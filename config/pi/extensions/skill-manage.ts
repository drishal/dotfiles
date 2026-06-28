/**
 * skill-manage — Dynamic skill creation + self-improvement loop for pi.
 *
 * Ports the Hermes Agent skill-creation machinery to pi as a native extension:
 *
 *   1. Registers a `skill_manage` tool the LLM can call to create / patch /
 *      edit / delete skills and their supporting files. The tool description
 *      carries the *when to use it* guidance the system prompt always sees,
 *      so the model does not have to remember to load a SKILL.md first.
 *   2. Adds a user-triggered `/skill-review` command that asks the agent to
 *      review the current conversation and codify anything worth saving. The
 *      review prompt keeps Hermes' *do-not-capture* rules, but Pi does not
 *      auto-trigger this by default; the user decides when to run it.
 *   3. Adds a `/learn <anything>` command that gathers sources and authors a
 *      single SKILL.md via `skill_manage`, mirroring Hermes' `/learn`.
 *
 * Skills are written to the Agent Skills standard locations (pi auto-discovers
 * `~/.pi/agent/skills/`, `~/.agents/skills/`, project `.pi/skills/`,
 * `.agents/skills/`). Create defaults to the global dir so the whole user
 * library lives in one place, like Hermes' `~/.hermes/skills/`.
 *
 * Authoring standards + the deterministic efficiency check are reimplemented
 * inline in TS (ported from @howaboua/pi-skill-skill-creator's
 * skill-efficiency-check.py) so the extension is self-contained and does not
 * shell out to a Python script whose install path may move.
 *
 * Tunables are at the top of the file — edit them freely.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// ─── Tunables ──────────────────────────────────────────────────────────────
// Tool calls in one turn before the optional automatic skill-review nudge fires.
// Default is 0: no automatic review. Prefer the explicit `/skill-review` command.
const NUDGE_INTERVAL = 0;
// Skip the autonomous nudge in non-interactive print/json/rpc modes if enabled.
const NUDGE_NONINTERACTIVE_ONLY = false;
// Default skills root for `create`. Global user library, single source of truth.
const GLOBAL_SKILLS_DIR = path.join(os.homedir(), ".pi", "agent", "skills");
// └──────────────────────────────────────────────────────────────────────────

const NUDGE_MARKER = "[skill-review]";

const NAME_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const CATEGORY_RE = /^[a-z][a-z0-9_/-]*$/;
const FORBIDDEN_HEADINGS =
	/^(#{1,6})\s+(when to use|do not use when|activation|triggers?)\b/im;
const REFERENCE_RE = /`((?:references|scripts|assets)\/[^`]+)`/g;
const SUPPORT_DIRS = ["references", "templates", "scripts", "assets"] as const;
const MAX_NAME = 64;
const MAX_DESC = 1024;
const MAX_SKILL_CHARS = 100_000;

type Action =
	| "create"
	| "patch"
	| "edit"
	| "delete"
	| "write_file"
	| "remove_file";

interface SkillManageParams {
	action: Action;
	name: string;
	content?: string;
	old_string?: string;
	new_string?: string;
	replace_all?: boolean;
	category?: string;
	file_path?: string;
	file_content?: string;
	absorbed_into?: string;
}

interface ToolResult {
	content: { type: "text"; text: string }[];
	details: Record<string, unknown>;
	isError?: boolean;
}

function ok(text: string, details: Record<string, unknown> = {}): ToolResult {
	return { content: [{ type: "text", text }], details };
}
function err(text: string, details: Record<string, unknown> = {}): ToolResult {
	return { content: [{ type: "text", text }], details, isError: true };
}

// ─── Filesystem helpers ───────────────────────────────────────────────────

function ensureDir(dir: string): void {
	fs.mkdirSync(dir, { recursive: true });
}

function listSkillRoots(projectTrusted: boolean, cwd: string): string[] {
	const roots = new Set<string>();
	roots.add(GLOBAL_SKILLS_DIR);
	roots.add(path.join(os.homedir(), ".agents", "skills"));
	if (projectTrusted) {
		for (const rel of [".pi/skills", ".agents/skills"]) {
			roots.add(path.resolve(cwd, rel));
		}
	}
	return [...roots];
}

interface FoundSkill {
	name: string;
	dir: string;
	skillMd: string;
}

function findSkill(
	name: string,
	projectTrusted: boolean,
	cwd: string,
): FoundSkill | undefined {
	for (const root of listSkillRoots(projectTrusted, cwd)) {
		if (!fs.existsSync(root)) continue;
		// Skill may be flat (root/<name>/SKILL.md) or categorized
		// (root/<category>/<name>/SKILL.md). Walk one level deep for the latter.
		const flat = path.join(root, name, "SKILL.md");
		if (fs.existsSync(flat)) {
			return { name, dir: path.dirname(flat), skillMd: flat };
		}
		for (const entry of safeReaddir(root)) {
			const nested = path.join(root, entry, name, "SKILL.md");
			if (fs.existsSync(nested)) {
				return { name, dir: path.dirname(nested), skillMd: nested };
			}
		}
	}
	return undefined;
}

function safeReaddir(dir: string): string[] {
	try {
		return fs.readdirSync(dir, { withFileTypes: true })
			.filter((d) => d.isDirectory())
			.map((d) => d.name)
			.filter((n) => !n.startsWith("."));
	} catch {
		return [];
	}
}

function listAllSkills(
	projectTrusted: boolean,
	cwd: string,
): FoundSkill[] {
	const out: FoundSkill[] = [];
	for (const root of listSkillRoots(projectTrusted, cwd)) {
		if (!fs.existsSync(root)) continue;
		for (const name of safeReaddir(root)) {
			const child = path.join(root, name);
			const flat = path.join(child, "SKILL.md");
			if (fs.existsSync(flat)) {
				out.push({ name, dir: child, skillMd: flat });
				continue;
			}
			// Categorized: child is a category dir.
			for (const sub of safeReaddir(child)) {
				const subPath = path.join(child, sub);
				const nested = path.join(subPath, "SKILL.md");
				if (fs.existsSync(nested)) {
					out.push({ name: sub, dir: subPath, skillMd: nested });
				}
			}
		}
	}
	return out;
}

// ─── Frontmatter parsing + validation (TS port of skill-efficiency-check.py) ─

function parseFrontmatter(text: string): {
	fields: Record<string, string>;
	body: string;
} {
	if (!text.startsWith("---\n") && !text.startsWith("---\r\n")) {
		throw new Error("missing YAML frontmatter (must start with ---)");
	}
	const end = text.indexOf("\n---", 4);
	if (end < 0) {
		throw new Error("unterminated YAML frontmatter (no closing ---)");
	}
	const raw = text.slice(4, end);
	const body = text.slice(end + 4).replace(/^[\r\n]+/, "");
	const fields: Record<string, string> = {};
	for (const line of raw.split(/\r?\n/)) {
		if (!line.trim() || line.startsWith(" ")) continue;
		const idx = line.indexOf(":");
		if (idx < 0) continue;
		const key = line.slice(0, idx).trim();
		let value = line.slice(idx + 1).trim();
		value = value.replace(/^"(.*)"$/, "$1").replace(/^'(.*)'$/, "$1");
		fields[key] = value;
	}
	return { fields, body };
}

function frontmatterScalarIssues(text: string): string[] {
	if (!text.startsWith("---")) return [];
	const end = text.indexOf("\n---", 4);
	if (end < 0) return [];
	const raw = text.slice(4, end);
	const issues: string[] = [];
	raw.split(/\r?\n/).forEach((line, i) => {
		if (!line.trim() || line.startsWith(" ") || !line.includes(":")) return;
		const [, value = ""] = line.split(/:(.*)/s);
		const v = value.trim();
		if (!v || v[0] === '"' || v[0] === "'" || v[0] === "|" || v[0] === ">") return;
		if (v.includes(": ") || /[{}[]]/.test(v)) {
			issues.push(
				`frontmatter scalar must be quoted (plain-scalar trap): "${line.trim()}". Use \`key: "value"\`, especially when the value contains ': '.`,
			);
		}
	});
	return issues;
}

interface CheckReport {
	issues: string[];
	warnings: string[];
	descriptionChars: number;
	bodyChars: number;
}

function efficiencyCheck(skillDir: string): CheckReport {
	const skillMd = path.join(skillDir, "SKILL.md");
	const report: CheckReport = {
		issues: [],
		warnings: [],
		descriptionChars: 0,
		bodyChars: 0,
	};
	let text = "";
	try {
		text = fs.readFileSync(skillMd, "utf-8");
	} catch {
		report.issues.push(`missing or unreadable SKILL.md: ${skillMd}`);
		return report;
	}

	report.issues.push(...frontmatterScalarIssues(text));

	let fields: Record<string, string> = {};
	let body = "";
	try {
		({ fields, body } = parseFrontmatter(text));
	} catch (e) {
		report.issues.push((e as Error).message);
	}
	const name = fields["name"] ?? "";
	const description = fields["description"] ?? "";
	report.descriptionChars = description.length;
	report.bodyChars = body.length;

	if (!name) report.issues.push("frontmatter missing name");
	else if (!NAME_RE.test(name))
		report.issues.push(`name is not kebab-case: ${name}`);

	if (!description) report.issues.push("frontmatter missing description");
	else {
		if (!/Use (when|for)\b/.test(description))
			report.warnings.push("description may not say when to use the skill");
		if (description.length > 600)
			report.issues.push(`description too long: ${description.length} chars > 600`);
		else if (description.length > 320)
			report.warnings.push(`description is long: ${description.length} chars > 320`);
	}

	if (FORBIDDEN_HEADINGS.test(body))
		report.issues.push(
			"body contains a trigger-selection heading (When to use / Do not use when / Activation / Triggers); keep trigger guidance in the frontmatter description",
		);

	REFERENCE_RE.lastIndex = 0;
	for (const rel of new Set(
		[...body.matchAll(REFERENCE_RE)].map((m) => m[1]),
	)) {
		if (!fs.existsSync(path.join(skillDir, rel))) {
			report.warnings.push(`referenced path does not exist: ${rel}`);
		}
	}
	return report;
}

function formatCheck(report: CheckReport): string {
	const lines: string[] = [];
	lines.push(`description_chars: ${report.descriptionChars}`);
	lines.push(`body_chars: ${report.bodyChars}`);
	lines.push("issues:");
	lines.push(
		report.issues.length
			? report.issues.map((i) => `  - ${i}`).join("\n")
			: "  - none",
	);
	lines.push("warnings:");
	lines.push(
		report.warnings.length
			? report.warnings.map((w) => `  - ${w}`).join("\n")
			: "  - none",
	);
	return lines.join("\n");
}

function validateName(name: string): string | null {
	if (!name) return "name is required";
	if (name.length > MAX_NAME)
		return `name exceeds ${MAX_NAME} characters`;
	if (!NAME_RE.test(name))
		return `name must be kebab-case (lowercase, hyphens, digits): ${name}`;
	return null;
}

function validateCategory(category: string | undefined): string | null {
	if (category === undefined || category === "") return null;
	if (!CATEGORY_RE.test(category))
		return `category must be lowercase letters/digits/hyphens/slashes: ${category}`;
	return null;
}

function validateFrontmatter(content: string): string | null {
	if (!content.trim()) return "content is empty";
	if (!content.startsWith("---"))
		return "SKILL.md must start with YAML frontmatter (---)";
	const end = content.slice(3).search(/\n---\s*\n/);
	if (end < 0)
		return "SKILL.md frontmatter is not closed (missing closing ---)";
	const yaml = content.slice(4, end + 3);
	let parsed: unknown;
	try {
		// Minimal YAML parse: only need top-level keys. Reuse parseFrontmatter.
		parsed = parseFrontmatter(content).fields;
	} catch (e) {
		return `YAML frontmatter parse error: ${(e as Error).message}`;
	}
	const fields = parsed as Record<string, string>;
	if (!("name" in fields)) return "frontmatter must include 'name'";
	if (!("description" in fields))
		return "frontmatter must include 'description'";
	if ((fields["description"] ?? "").length > MAX_DESC)
		return `description exceeds ${MAX_DESC} characters`;
	const body = content.slice(end + 3 + 4).trim();
	if (!body) return "SKILL.md must have content after the frontmatter";
	return null;
}

function validateContentSize(content: string): string | null {
	if (content.length > MAX_SKILL_CHARS)
		return `content exceeds ${MAX_SKILL_CHARS} characters`;
	return null;
}

function validateSupportPath(file_path: string): string | null {
	const norm = file_path.replace(/^\/+/, "");
	const top = norm.split("/")[0];
	if (!SUPPORT_DIRS.includes(top as (typeof SUPPORT_DIRS)[number])) {
		return `file_path must be under one of: ${SUPPORT_DIRS.join(", ")} (got: ${file_path})`;
	}
	if (norm.includes("..")) return "file_path must not escape the skill directory";
	return null;
}

// ─── Provenance ─────────────────────────────────────────────────────────────

function writeProvenance(
	skillDir: string,
	author: string,
	source: string,
): void {
	const prov = path.join(skillDir, ".pi-provenance.json");
	const payload = {
		created_by: author,
		created_at: new Date().toISOString(),
		source,
	};
	try {
		fs.writeFileSync(prov, JSON.stringify(payload, null, 2) + "\n", "utf-8");
	} catch {
		/* provenance is best-effort */
	}
}

function isAgentCreated(skillDir: string): boolean {
	return fs.existsSync(path.join(skillDir, ".pi-provenance.json"));
}

// ─── Archive log for delete with absorbed_into ────────────────────────────

function recordArchive(
	name: string,
	dir: string,
	absorbedInto: string | undefined,
): void {
	const logFile = path.join(GLOBAL_SKILLS_DIR, ".skill_archives.json");
	let log: unknown[] = [];
	try {
		log = JSON.parse(fs.readFileSync(logFile, "utf-8"));
	} catch {
		log = [];
	}
	(log as unknown[]).push({
		name,
		dir,
		absorbed_into: absorbedInto ?? "",
		archived_at: new Date().toISOString(),
	});
	try {
		ensureDir(GLOBAL_SKILLS_DIR);
		fs.writeFileSync(logFile, JSON.stringify(log, null, 2) + "\n", "utf-8");
	} catch {
		/* best-effort */
	}
}

// ─── Drop-in replacement for skill_view when validating ────────────────────

function readSkillMd(skillMd: string): string {
	return fs.readFileSync(skillMd, "utf-8");
}

// ─── The tool handler ──────────────────────────────────────────────────────

function handleSkillManage(
	params: SkillManageParams,
	projectTrusted: boolean,
	cwd: string,
): ToolResult {
	const action = params.action;
	const name = (params.name ?? "").trim();

	if (action === "create") {
		if (!params.content) {
			return err(
				"content is required for 'create'. Provide the full SKILL.md text (frontmatter + body).",
			);
		}
		const nameErr = validateName(name);
		if (nameErr) return err(nameErr);
		const catErr = validateCategory(params.category);
		if (catErr) return err(catErr);
		const fmErr = validateFrontmatter(params.content);
		if (fmErr) return err(fmErr);
		const sizeErr = validateContentSize(params.content);
		if (sizeErr) return err(sizeErr);

		// Frontmatter name should match the requested name.
		try {
			const { fields } = parseFrontmatter(params.content);
			if ((fields["name"] ?? "").trim() !== name) {
				return err(
					`frontmatter 'name' ("${fields["name"]}") must equal the requested name ("${name}")`,
				);
			}
		} catch (e) {
			return err(`frontmatter parse error: ${(e as Error).message}`);
		}

		// Collision check across all roots.
		const existing = findSkill(name, projectTrusted, cwd);
		if (existing) {
			return err(
				`a skill named '${name}' already exists at ${existing.dir}. Use action='patch' or action='edit' instead.`,
			);
		}

		const targetDir = params.category
			? path.join(GLOBAL_SKILLS_DIR, params.category, name)
			: path.join(GLOBAL_SKILLS_DIR, name);
		ensureDir(targetDir);
		const skillMd = path.join(targetDir, "SKILL.md");
		try {
			fs.writeFileSync(skillMd, params.content, "utf-8");
		} catch (e) {
			return err(`failed to write SKILL.md: ${(e as Error).message}`);
		}
		writeProvenance(targetDir, "agent", "skill_manage:create");
		const report = efficiencyCheck(targetDir);
		const hardIssues = report.issues.length;
		const summary =
			`Created skill '${name}' at ${targetDir}\n` +
			`provenance: agent-created (.pi-provenance.json)\n` +
			`efficiency check:\n${formatCheck(report)}` +
			(hardIssues
				? `\n\n⚠️ ${hardIssues} hard issue(s) detected. Please fix and call skill_manage(action='patch', ...) or 'edit'.`
				: "");
		return ok(summary, { dir: targetDir, issues: report.issues });
	}

	if (action === "edit") {
		if (!params.content) {
			return err(
				"content is required for 'edit'. Provide the full updated SKILL.md text. Read the skill first with the `read` tool.",
			);
		}
		const existing = findSkill(name, projectTrusted, cwd);
		if (!existing) {
			return err(
				`skill '${name}' not found. Create it first with action='create'.`,
			);
		}
		const fmErr = validateFrontmatter(params.content);
		if (fmErr) return err(fmErr);
		const sizeErr = validateContentSize(params.content);
		if (sizeErr) return err(sizeErr);
		try {
			fs.writeFileSync(existing.skillMd, params.content, "utf-8");
		} catch (e) {
			return err(`failed to write SKILL.md: ${(e as Error).message}`);
		}
		const report = efficiencyCheck(existing.dir);
		const summary =
			`Updated skill '${name}' at ${existing.dir}\n` +
			`efficiency check:\n${formatCheck(report)}`;
		return ok(summary, { dir: existing.dir, issues: report.issues });
	}

	if (action === "patch") {
		if (!params.old_string || params.new_string === undefined) {
			return err(
				"old_string and new_string are required for 'patch'. new_string may be '' to delete.",
			);
		}
		const existing = findSkill(name, projectTrusted, cwd);
		if (!existing) {
			return err(
				`skill '${name}' not found. Use action='create' to make a new one.`,
			);
		}
		const target = params.file_path
			? path.join(existing.dir, params.file_path.replace(/^\/+/, ""))
			: existing.skillMd;
		// Resolve to real path
		const targetAbs = path.resolve(target);
		if (!targetAbs.startsWith(path.resolve(existing.dir))) {
			return err("file_path must stay within the skill directory");
		}
		if (!fs.existsSync(targetAbs)) {
			return err(`target file not found: ${targetAbs}`);
		}
		let content: string;
		try {
			content = fs.readFileSync(targetAbs, "utf-8");
		} catch (e) {
			return err(`failed to read ${targetAbs}: ${(e as Error).message}`);
		}
		const occurrences = content.split(params.old_string).length - 1;
		if (occurrences === 0) {
			return err(
				`old_string not found in ${targetAbs}. Use the \`read\` tool to see the current content.`,
			);
		}
		if (occurrences > 1 && !params.replace_all) {
			return err(
				`old_string matches ${occurrences} times in ${targetAbs}. Include more surrounding context to make it unique, or set replace_all=true.`,
			);
		}
		const updated = params.replace_all
			? content.split(params.old_string).join(params.new_string!)
			: content.replace(params.old_string, params.new_string!);
		const sizeErr = validateContentSize(updated);
		if (sizeErr) return err(sizeErr);
		try {
			fs.writeFileSync(targetAbs, updated, "utf-8");
		} catch (e) {
			return err(`failed to write ${targetAbs}: ${(e as Error).message}`);
		}
		const report = targetAbs.endsWith("SKILL.md")
			? efficiencyCheck(existing.dir)
			: { issues: [], warnings: [], descriptionChars: 0, bodyChars: 0 };
		const summary =
			`Patched ${
				path.relative(existing.dir, targetAbs) || "SKILL.md"
			} in skill '${name}' (${occurrences} replacement${occurrences > 1 ? "s" : ""}).\n` +
			(report.issues.length || report.warnings.length
				? `efficiency check:\n${formatCheck(report)}`
				: "efficiency check: clean");
		return ok(summary, { file: targetAbs, issues: report.issues });
	}

	if (action === "delete") {
		const existing = findSkill(name, projectTrusted, cwd);
		if (!existing) {
			return err(`skill '${name}' not found.`);
		}
		if (params.absorbed_into !== undefined) {
			if (params.absorbed_into !== "") {
				const umbrella = findSkill(params.absorbed_into, projectTrusted, cwd);
				if (!umbrella) {
					return err(
						`absorbed_into='${params.absorbed_into}' but that skill does not exist. Create or patch the umbrella first, then delete.`,
					);
				}
			}
			recordArchive(name, existing.dir, params.absorbed_into);
		} else {
			recordArchive(name, existing.dir, undefined);
		}
		try {
			fs.rmSync(existing.dir, { recursive: true, force: true });
		} catch (e) {
			return err(`failed to remove skill dir: ${(e as Error).message}`);
		}
		const intent =
			params.absorbed_into === undefined
				? "no forwarding target declared"
				: params.absorbed_into === ""
					? "pruned (no forwarding target)"
					: `merged into '${params.absorbed_into}'`;
		return ok(
			`Deleted skill '${name}' (was at ${existing.dir}). Intent: ${intent}. Archived to .skill_archives.json.`,
			{ dir: existing.dir, absorbed_into: params.absorbed_into ?? null },
		);
	}

	if (action === "write_file") {
		if (!params.file_path) return err("file_path is required for 'write_file'");
		if (params.file_content === undefined)
			return err("file_content is required for 'write_file'");
		const pathErr = validateSupportPath(params.file_path);
		if (pathErr) return err(pathErr);
		const existing = findSkill(name, projectTrusted, cwd);
		if (!existing) {
			return err(
				`skill '${name}' not found. Create the skill first with action='create'.`,
			);
		}
		const target = path.join(
			existing.dir,
			params.file_path.replace(/^\/+/, ""),
		);
		ensureDir(path.dirname(target));
		try {
			fs.writeFileSync(target, params.file_content, "utf-8");
		} catch (e) {
			return err(`failed to write ${target}: ${(e as Error).message}`);
		}
		const report = efficiencyCheck(existing.dir);
		return ok(
			`Wrote ${params.file_path} in skill '${name}' (${existing.dir}).\nefficiency check:\n${formatCheck(report)}`,
			{ file: target, issues: report.issues },
		);
	}

	if (action === "remove_file") {
		if (!params.file_path) return err("file_path is required for 'remove_file'");
		const pathErr = validateSupportPath(params.file_path);
		if (pathErr) return err(pathErr);
		const existing = findSkill(name, projectTrusted, cwd);
		if (!existing) return err(`skill '${name}' not found.`);
		const target = path.join(
			existing.dir,
			params.file_path.replace(/^\/+/, ""),
		);
		if (!fs.existsSync(target)) return err(`file not found: ${target}`);
		try {
			fs.unlinkSync(target);
		} catch (e) {
			return err(`failed to remove ${target}: ${(e as Error).message}`);
		}
		return ok(`Removed ${params.file_path} from skill '${name}'.`, {
			file: target,
		});
	}

	return err(`unknown action: ${action}`);
}

// ─── Review prompt (near-verbatim port of Hermes' `_SKILL_REVIEW_PROMPT`) ──

const SKILL_REVIEW_PROMPT = `Review the work completed in this session and update the skill library only when there is durable, reusable learning. Empty-but-honest beats a rotting library: if nothing durable was learned, say 'Nothing durable to save this turn.' and stop.

Target shape of the library: CLASS-LEVEL skills, each with a rich SKILL.md and a \`references/\` directory for session-specific detail. Not a long flat list of narrow one-session-one-skill entries. Prefer patching or adding references under an existing umbrella over creating new skill directories.

Signals to look for (any one of these warrants action):
  • User corrected your style, tone, format, legibility, or verbosity. Frustration signals like 'stop doing X', 'this is too verbose', 'don't format like this', 'why are you explaining', 'just give me the answer', or an explicit 'remember this' are FIRST-CLASS skill signals, not just memory signals. Update the relevant skill(s) to embed the preference so the next session starts already knowing.
  • User corrected your workflow, approach, or sequence of steps. Encode the correction as a pitfall or explicit step in the skill that governs that class of task.
  • Non-trivial technique, fix, workaround, debugging path, or tool-usage pattern emerged that a future session would benefit from. Capture it.
  • A skill that got loaded or consulted this session turned out to be wrong, missing a step, or outdated. Patch it NOW.

Preference order — prefer the earliest action that fits, but do pick one when a signal above fired:
  1. UPDATE A SKILL YOU LOADED THIS SESSION. Use the \`read\` tool to look back at any SKILL.md you opened this turn. If one of them covers the territory of the new learning, PATCH that one first via \`skill_manage(action='patch', name='<skill>', old_string='...', new_string='...')\`.
  2. UPDATE AN EXISTING UMBRELLA. If no loaded skill fits but an existing class-level skill does (call \`skill_manage\`-style discovery by reading likely skills under ~/.pi/agent/skills/), patch it. Add a subsection, a pitfall, or broaden a trigger.
  3. ADD A SUPPORT FILE under an existing umbrella. Use \`skill_manage(action='write_file', ...)\` with file_path starting with \`references/\`, \`templates/\`, or \`scripts/\`. Add a one-line pointer to it in the umbrella's SKILL.md.
  4. CREATE A NEW CLASS-LEVEL SKILL only if the user explicitly asked for one or you have asked for and received confirmation. Use \`skill_manage(action='create', name='<class-level-name>', content='---\\nname: ...\\ndescription: "Use when <trigger>. <behavior>."\\n---\\n# ...\\n', category='<optional>')\`. The name MUST be at the class level — NOT a specific PR number, error string, feature codename, library-alone name, or 'fix-X / debug-Y / audit-Z-today' session artifact. If the proposed name only makes sense for today's task, it's wrong — fall back to (1), (2), or (3).

User-preference embedding (important): when the user expressed a style/format/workflow preference, the update belongs in the SKILL.md body, not just in memory. Memory captures 'who the user is'; skills capture 'how to do this class of task for this user'.

DO NOT capture (these become persistent self-imposed constraints that bite you later when the environment changes):
  • Environment-dependent failures: missing binaries, fresh-install errors, post-migration path mismatches, 'command not found', unconfigured credentials, uninstalled packages. The user can fix these — they are not durable rules.
  • Negative claims about tools or features ('browser tools do not work', 'X tool is broken', 'cannot use Y'). These harden into refusals the agent cites against itself for months after the actual problem was fixed.
  • Session-specific transient errors that resolved before the turn ended.

If nothing durable was learned, say 'Nothing durable to save this turn.' and stop. Do not create a skill just to satisfy the review — empty-but-honest beats a rotting library.

When in doubt about an existing skill's current shape, read it with the \`read\` tool before patching.`;

// ─── /learn command prompt (adapted from Hermes' learn_prompt.py) ─────────

function buildLearnPrompt(args: string): string {
	const trimmed = args.trim();
	return `Author a new reusable skill from the source(s) below, using \`skill_manage(action='create', ...)\` once you have understood the workflow.

Source: ${trimmed || "(whatever you can infer from the current conversation)"}

Steps:
1. Gather the source(s). For a directory use the \`bash\` tool (\`ls\`, \`find\`, \`rg\`) and \`read\`. For a URL use the \`obscura\`/web tools. For "what I just did in this conversation", reflect on the transcript. For pasted material, use the text the user provided.
2. Identify the recurring, class-level workflow — not the one-time specifics. If the workflow is genuinely one-off, say so and stop; do not bloat the library.
3. Draft a single SKILL.md following the Agent Skills standard:
   - frontmatter: \`name\` (kebab-case, <=64 chars) and \`description\` (one sentence, >= "Use when <trigger>. <behavior>.", <= 600 chars, quoted if it contains ': '). Put all trigger guidance in the description only.
   - body: ordered workflow with exact commands, pitfalls, and verification steps. Move bulky reference material into \`references/\` if the main file would exceed ~14k chars.
   - default to minimal shape: one SKILL.md, add \`references/\`/\`templates/\`/\`scripts/\` only when genuinely warranted.
4. Call \`skill_manage(action='create', name='<name>', content='<full SKILL.md>', category='<optional>')\` to write the skill. The tool runs an efficiency check and reports any hard issues; fix them and re-patch if needed.
5. Summarize what you created and why, and quote the final trigger sentence so it is easy to sanity-check.`;
}

// ─── Extension entrypoint ──────────────────────────────────────────────────

export default function skillManageExtension(pi: ExtensionAPI): void {
	// Per-turn state for the skill-review nudge.
	let toolCallsThisTurn = 0;
	let isNudgeTurn = false;
	let suppressNextNudge = false;

	pi.on("before_agent_start", (event) => {
		toolCallsThisTurn = 0;
		isNudgeTurn =
			typeof event.prompt === "string" && event.prompt.includes(NUDGE_MARKER);
		// After a nudge turn we suppress one more cycle so the review's own
		// wide-net exploration cannot immediately re-arm the nudge.
		if (suppressNextNudge) {
			isNudgeTurn = true;
			suppressNextNudge = false;
		}
	});

	pi.on("tool_execution_end", (event) => {
		if (event.toolName === "skill_manage") {
			// Using the tool itself resets the nudge counter (matches Hermes).
			toolCallsThisTurn = 0;
		} else {
			toolCallsThisTurn += 1;
		}
	});

	pi.on("turn_end", (_event, ctx) => {
		if (NUDGE_INTERVAL <= 0) return;
		if (isNudgeTurn) return;
		if (ctx.mode === "print" || ctx.mode === "json") {
			if (!NUDGE_NONINTERACTIVE_ONLY) return;
		}
		if (toolCallsThisTurn < NUDGE_INTERVAL) return;

		toolCallsThisTurn = 0;
		suppressNextNudge = true;
		// Deliver as a follow-up so the nudge never competes with the user's
		// in-flight task and only fires once the agent is idle.
		pi.sendUserMessage(`${NUDGE_MARKER} ${SKILL_REVIEW_PROMPT}`, {
			deliverAs: "followUp",
		});
		if (ctx.hasUI) {
			ctx.ui.notify(
				`skill review scheduled (${NUDGE_INTERVAL}+ tool calls)`,
				"info",
			);
		}
	});

	// ── The tool ──────────────────────────────────────────────────────────
	pi.registerTool({
		name: "skill_manage",
		label: "Manage Skill",
		description: `Manage skills (create, update, delete). Skills are your procedural memory — reusable approaches for recurring task types. New skills are written to ${GLOBAL_SKILLS_DIR} (global) by default; existing skills can be modified wherever they live.

Actions: create (full SKILL.md + optional category), patch (old_string/new_string — preferred for fixes), edit (full SKILL.md rewrite — major overhauls only), delete (with optional absorbed_into), write_file, remove_file.

On delete, pass absorbed_into="<umbrella>" when merging this skill's content into another (the target must already exist — create/patch it first), or absorbed_into="" when pruning with no forwarding target. The intent is recorded in ~/.pi/agent/skills/.skill_archives.json.

Create only when the user explicitly asked for a new skill, or after asking for and receiving confirmation. Do not create new skills for short troubleshooting turns or one-offs.
Update when: instructions are stale/wrong, OS-specific failures appeared, or missing steps/pitfalls were found during use. If you loaded a skill and hit issues it did not cover, patch it immediately.

After difficult/iterative tasks, offer to save as a skill. Prefer patching existing skills or adding references under an umbrella. Confirm with the user before creating or deleting.

Good skills: a trigger-rich description in frontmatter, ordered steps with exact commands, a pitfalls section, and verification steps. Use the \`read\` tool on existing skills under ~/.pi/agent/skills/ to see format examples. The tool runs an efficiency check after every write and reports hard issues (invalid frontmatter, description too long, forbidden trigger-selection headings in the body); fix those and call patch/edit before reporting done.

A SKILL.md's frontmatter \`name\` MUST match the \`name\` argument. Never create a skill whose name is a PR number, error string, feature codename, or 'fix-X-today' session artifact — name at the class level.`,
		promptSnippet:
			"Create, patch, or delete reusable skills (SKILL.md) for recurring workflows",
		promptGuidelines: [
			"Use skill_manage action='patch' to improve loaded/existing skills when they are wrong, stale, or missing a step.",
			"Create new skills with skill_manage action='create' only when the user explicitly asked for a skill or after receiving confirmation.",
			"Prefer skill_manage action='patch' or action='write_file' under an existing umbrella over creating a new skill directory.",
			"When skill_manage is unavailable, prefer editing an existing skill over creating a new one with a similar name.",
		],
		parameters: Type.Object({
			action: StringEnum(
				[
					"create",
					"patch",
					"edit",
					"delete",
					"write_file",
					"remove_file",
				] as const,
				{ description: "The action to perform." },
			),
			name: Type.String({
				description:
					"Skill name (lowercase, hyphens, max 64 chars, kebab-case). Must match frontmatter 'name' for create/edit. Must name an existing skill for patch/edit/delete/write_file/remove_file.",
			}),
			content: Type.Optional(
				Type.String({
					description:
						"Full SKILL.md content (YAML frontmatter + markdown body). Required for 'create' and 'edit'. For 'edit', read the skill first with the `read` tool and provide the complete updated text.",
				}),
			),
			old_string: Type.Optional(
				Type.String({
					description:
						"Text to find for 'patch'. Must be unique unless replace_all=true. Include enough surrounding context to ensure uniqueness.",
				}),
			),
			new_string: Type.Optional(
				Type.String({
					description:
						"Replacement text for 'patch'. May be the empty string to delete the matched text.",
				}),
			),
			replace_all: Type.Optional(
				Type.Boolean({
					description:
						"For 'patch': replace all occurrences instead of requiring a unique match (default: false).",
				}),
			),
			category: Type.Optional(
				Type.String({
					description:
						"Optional category for organizing the skill (e.g. 'devops', 'data-science'). Creates a subdirectory grouping. Only used with 'create'.",
				}),
			),
			file_path: Type.Optional(
				Type.String({
					description:
						"Supporting file path within the skill dir. For 'write_file'/'remove_file': required, must be under references/, templates/, scripts/, or assets/. For 'patch': optional, defaults to SKILL.md if omitted.",
				}),
			),
			file_content: Type.Optional(
				Type.String({
					description: "Content for the file. Required for 'write_file'.",
				}),
			),
			absorbed_into: Type.Optional(
				Type.String({
					description:
						"For 'delete' only — pass the umbrella skill name when this skill's content was merged into another (target must already exist, so create/patch it first), or pass the empty string when pruning with no forwarding target. Omitting is allowed but records no forwarding intent.",
				}),
			),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx): Promise<ToolResult> {
			try {
				const projectTrusted = ctx.isProjectTrusted();
				return handleSkillManage(
					params as unknown as SkillManageParams,
					projectTrusted,
					ctx.cwd,
				);
			} catch (e) {
				return err(
					`unexpected error in skill_manage: ${(e as Error).message}`,
				);
			}
		},
	});

	// ── /skill-review command ────────────────────────────────────────────
	pi.registerCommand("skill-review", {
		description:
			"Review the current session for durable skill-library updates (user-triggered; conservative by default)",
		handler: async (_args, ctx) => {
			if (ctx.hasUI) {
				ctx.ui.notify("Skill review queued", "info");
			}
			pi.sendUserMessage(`${NUDGE_MARKER} ${SKILL_REVIEW_PROMPT}`, {
				deliverAs: "followUp",
			});
		},
	});

	// ── /learn command ───────────────────────────────────────────────────
	pi.registerCommand("learn", {
		description:
			"Author a reusable skill from a source (directory, URL, pasted notes, or 'what I just did'): /learn <source description>",
		handler: async (args, ctx) => {
			const prompt = buildLearnPrompt(args);
			if (ctx.hasUI) {
				ctx.ui.notify("Learning a skill — follow-up queued", "info");
			}
			pi.sendUserMessage(prompt, { deliverAs: "followUp" });
		},
	});

	// ── /skills-show command — quick listing of existing skills ──────────
	pi.registerCommand("skills-show", {
		description: "List all discovered pi skills (global + trusted project)",
		handler: async (_args, ctx) => {
			const skills = listAllSkills(ctx.isProjectTrusted(), ctx.cwd);
			if (skills.length === 0) {
				ctx.ui.notify("No skills discovered.", "info");
				return;
			}
			const lines = skills.map(
				(s) =>
					`${isAgentCreated(s.dir) ? "+" : " "} ${s.name}  —  ${path.relative(
						path.dirname(path.dirname(s.dir)) || ".",
						s.dir,
					)}`,
			);
			const sel = await ctx.ui.select("Discovered skills", lines);
			if (!sel) return;
		},
	});
}