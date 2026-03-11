export const AttentionNotify = async ({ $ }) => {
  const getFocusedWindow = async () => {
    try {
      const focusedWindow = await $`niri msg --json focused-window`.text();
      return JSON.parse(focusedWindow);
    } catch (error) {
      return null;
    }
  };

  const selfWindow = await getFocusedWindow();
  const selfWindowId = selfWindow?.id ?? null;

  const isOpencodeFocused = async () => {
    const focusedWindow = await getFocusedWindow();
    if (!focusedWindow) {
      return false;
    }

    if (selfWindowId === null) {
      return false;
    }

    return focusedWindow.id === selfWindowId;
  };

  const playSound = async () => {
    await $`paplay /usr/share/sounds/freedesktop/stereo/complete.oga`;
  };

  const notify = async (title, message) => {
    try {
      if (await isOpencodeFocused()) {
        return;
      }

      const appName = selfWindowId ? `opencode-${selfWindowId}` : "opencode";
      await $`notify-send -a ${appName} -i $HOME/.config/opencode/plugin/opencode-logo-dark.png ${title} ${message}`;
      await playSound();
    } catch (error) {
      console.error("Notification failed", error);
    }
  };

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("opencode", "Session completed — review output");
      }

      if (event.type === "session.error") {
        await notify("opencode", "Session error — check logs");
      }

      if (event.type.startsWith("permission.")) {
        await notify("opencode", `Permission — action needed`);
      }
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        const questionHeader = input.params?.questions?.[0]?.header;
        const summary = questionHeader
          ? `Input needed — ${questionHeader}`
          : "Input needed — question ready";
        await notify("opencode", summary);
      }
    },
  };
};
