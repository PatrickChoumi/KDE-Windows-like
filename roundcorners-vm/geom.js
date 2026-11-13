for (const w of workspace.windowList()) {
  if (w.caption.indexOf("Konsole") >= 0 || w.resourceClass.indexOf("konsole") >= 0)
    print("GEOM " + w.frameGeometry.x + " " + w.frameGeometry.y + " " + w.frameGeometry.width + " " + w.frameGeometry.height + " | client " + w.clientGeometry.x + " " + w.clientGeometry.y + " " + w.clientGeometry.width + " " + w.clientGeometry.height);
}
