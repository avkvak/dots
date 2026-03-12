:root {
    --cc-bg: rgba({{ background_rgb }}, 0.94);
    --noti-border-color: rgba({{ accent_rgb }}, 0.7);
    --noti-bg: {{ background_rgb }};
    --noti-bg-alpha: 0.98;
    --noti-bg-darker: shade({{ background }}, 0.85);
    --noti-bg-hover: {{ selection_background }};
    --noti-bg-focus: rgba({{ selection_background_rgb }}, 0.35);
    --noti-close-bg: rgba({{ accent_rgb }}, 0.18);
    --noti-close-bg-hover: rgba({{ accent_rgb }}, 0.3);
    --text-color: {{ foreground }};
    --text-color-disabled: rgba({{ foreground_rgb }}, 0.65);
    --bg-selected: {{ selection_background }};
    --border: 1px solid var(--noti-border-color);
    --border-radius: 0px;
    --notification-shadow: none;
    --font-size-body: 13px;
    --font-size-summary: 13px;
}

@define-color cc-bg rgba({{ background_rgb }}, 0.94);
@define-color noti-border-color rgba({{ accent_rgb }}, 0.7);
@define-color noti-bg rgba({{ background_rgb }}, 0.98);
@define-color noti-bg-opaque {{ background }};
@define-color noti-bg-darker shade({{ background }}, 0.85);
@define-color noti-bg-hover {{ selection_background }};
@define-color noti-bg-hover-opaque {{ selection_background }};
@define-color noti-bg-focus rgba({{ selection_background_rgb }}, 0.35);
@define-color noti-close-bg rgba({{ accent_rgb }}, 0.18);
@define-color noti-close-bg-hover rgba({{ accent_rgb }}, 0.3);
@define-color text-color {{ foreground }};
@define-color text-color-disabled rgba({{ foreground_rgb }}, 0.65);
@define-color bg-selected {{ selection_background }};

* {
    font-family: "JetBrainsMono Nerd Font";
    border-radius: 0;
    box-shadow: none;
    text-shadow: none;
}

.control-center {
    border: 2px solid rgba({{ accent_rgb }}, 0.85);
    padding: 12px;
}

.notification-row .notification-background {
    padding: 6px 0;
}

.notification-row .notification-background .notification,
.notification-group {
    border-radius: 0;
}

.notification-row .notification-background .notification .notification-default-action,
.notification-row .notification-background .notification .notification-action > button,
.widget-title > button,
.widget-dnd > switch,
.close-button {
    border-radius: 0;
}

.notification-row .notification-background .notification .notification-action > button {
    padding: 4px 8px;
    font-size: 12px;
    font-weight: 400;
}

.notification-row .notification-background .notification {
    border: 1px solid rgba({{ accent_rgb }}, 0.55);
}

.notification-row .notification-background .notification .notification-default-action {
    padding: 8px 10px;
}

.notification-row .notification-background .notification .notification-default-action:hover {
    background: rgba({{ selection_background_rgb }}, 0.16);
}

.notification-row .notification-background .notification .notification-default-action .notification-content .text-box .summary,
.notification-row .notification-background .notification .notification-default-action .notification-content .text-box .time {
    font-size: 13px;
}

.notification-row .notification-background .notification .notification-default-action .notification-content .text-box .body {
    font-size: 12px;
}

.widget-title {
    margin: 0 0 10px;
}

.widget-title label {
    font-size: 13px;
    font-weight: 700;
    color: {{ foreground }};
}

.widget-title > button {
    min-height: 0;
    padding: 4px 8px;
    font-size: 12px;
    font-weight: 400;
    background: rgba({{ accent_rgb }}, 0.12);
    border: 1px solid rgba({{ accent_rgb }}, 0.55);
}

.widget-title > button:hover {
    background: rgba({{ selection_background_rgb }}, 0.18);
}

.widget-dnd {
    margin: 0 0 10px;
}

.widget-dnd label {
    font-size: 12px;
    font-weight: 400;
    color: rgba({{ foreground_rgb }}, 0.85);
}

.widget-dnd > switch {
    min-width: 34px;
    min-height: 18px;
    background: rgba({{ accent_rgb }}, 0.12);
    border: 1px solid rgba({{ accent_rgb }}, 0.55);
}

.widget-dnd > switch:checked {
    background: rgba({{ selection_background_rgb }}, 0.85);
}

.widget-dnd > switch slider {
    background: {{ foreground }};
    min-width: 12px;
    min-height: 12px;
}

.notification-group-headers,
.notification-group-icon {
    margin: 0;
}
