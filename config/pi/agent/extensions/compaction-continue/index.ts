import {
	analyzeCompactionRecovery,
	analyzeLatestAssistantStall,
	analyzeRalphBranchForStall,
	assistantRequestsContinuation,
	assistantRequestsRalphContinuation,
	assistantStoppedForContextLimit,
	isRalphLoopPromptText,
	isStardockLoopPromptText,
	messageText,
	parseRalphPrompt,
	shouldRecoverStalledAssistantTurn,
	userRequestsSimpleContinuation,
} from "./src/analysis.ts";
import { buildWatchdogNudgePrompt, WATCHDOG_ANSWER_TOOL, WATCHDOG_NUDGE_PROMPT } from "./src/model.ts";
import { registerCompactionContinue } from "./src/runtime.ts";

export {
	analyzeCompactionRecovery,
	analyzeLatestAssistantStall,
	analyzeRalphBranchForStall,
	assistantRequestsContinuation,
	assistantRequestsRalphContinuation,
	assistantStoppedForContextLimit,
	buildWatchdogNudgePrompt,
	isRalphLoopPromptText,
	isStardockLoopPromptText,
	messageText,
	parseRalphPrompt,
	shouldRecoverStalledAssistantTurn,
	userRequestsSimpleContinuation,
	WATCHDOG_ANSWER_TOOL,
	WATCHDOG_NUDGE_PROMPT,
};

export default registerCompactionContinue;
