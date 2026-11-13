for (const w of workspace.windowList()) {
    if (w.caption.indexOf("Konsole") >= 0) { w.demandsAttention = true; print("attention-script: " + w.caption + " -> " + w.demandsAttention); }
}
