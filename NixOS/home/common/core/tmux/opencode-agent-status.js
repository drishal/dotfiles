const childSessions = new Set();

function report(state) {
  if (!process.env.TMUX || !process.env.TMUX_PANE) return;
  try {
    Bun.spawn(["@tmuxAgentState@", "opencode", state], {
      stdin: "ignore",
      stdout: "ignore",
      stderr: "ignore",
    });
  } catch {
    // Agent status must never interfere with OpenCode.
  }
}

function sessionId(properties) {
  return typeof properties?.sessionID === "string"
    ? properties.sessionID
    : undefined;
}

function stateFromStatus(status) {
  const kind = typeof status === "string" ? status : status?.type;
  switch (kind?.toLowerCase()) {
    case "idle":
      return "done";
    case "active":
    case "busy":
    case "pending":
    case "retry":
    case "running":
    case "streaming":
    case "working":
      return "working";
    default:
      return undefined;
  }
}

export const TmuxAgentStatusPlugin = async () => {
  if (!process.env.TMUX || !process.env.TMUX_PANE) return {};

  return {
    "chat.message": async ({ sessionID }) => {
      if (!childSessions.has(sessionID)) report("working");
    },
    event: async ({ event }) => {
      const type = event?.type;
      const properties = event?.properties ?? {};
      const id = sessionId(properties);
      const info = properties.info;

      if (info?.id && info.parentID) childSessions.add(info.id);
      if (id && childSessions.has(id)) {
        if (type === "permission.asked" || type === "question.asked") {
          report("ask");
        } else if (
          type === "permission.replied" ||
          type === "question.replied" ||
          type === "question.rejected"
        ) {
          report("working");
        }
        return;
      }

      switch (type) {
        case "session.status": {
          const state = stateFromStatus(properties.status);
          if (state) report(state);
          break;
        }
        case "tool.execute.before":
        case "tool.execute.after":
        case "permission.replied":
        case "question.replied":
        case "question.rejected":
        case "session.compacted":
          report("working");
          break;
        case "permission.asked":
        case "question.asked":
        case "session.error":
          report("ask");
          break;
        case "session.idle":
          report("done");
          break;
        default:
          break;
      }
    },
  };
};
