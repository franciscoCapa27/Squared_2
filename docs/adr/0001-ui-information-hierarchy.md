# UI Information Hierarchy

The UI pass will use a shared information hierarchy: panels provide compact context and can be collapsed, components keep their action-critical state visible, and `i` controls/tooltips reveal deeper detail. Panels start expanded on load, while contextual help is attached to the component it explains rather than added to every panel header. This preserves the game’s quiet visual language while making dense systems understandable on desktop and touch layouts.
