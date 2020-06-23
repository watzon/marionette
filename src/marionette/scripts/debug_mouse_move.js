var id = "marionetteMouseDebugging";
var dotID = "marionetteMouseDebuggingDot";
var descID = "marionetteMouseDebuggingDescription";
var element = arguments[0];
var x = arguments[1];
var y = arguments[2];
var rect = element.getBoundingClientRect();
var el, redDot, description;
if (document.getElementById(id) == null) {
  el = document.createElement("div");
  redDot = document.createElement("div");
  description = document.createElement("div");
  el.appendChild(redDot);
  el.appendChild(description);
  el.id = id;
  redDot.id = dotID;
  description.id = descID;
  el.style.position = "absolute";
  el.style.zIndex = "100000000";
  el.style.display = "flex";
  el.style.pointerEvents = "none";
  redDot.style.borderRadius = "5px";
  redDot.style.border = "2px solid red";
  redDot.style.backgroundColor = "red";
  redDot.style.width = "5px";
  redDot.style.height = "5px";
  redDot.style.display = "inline-block";
  redDot.style.pointerEvents = "none";
  redDot.style.marginRight = "5px";
  description.style.display = "inline-block";
  description.style.border = "1px solid black";
  description.style.backgroundColor = "white";
  description.style.borderRadius = "3px";
  description.style.pointerEvents = "none";
  description.style.paddingLeft = "5px";
  description.style.paddingRight = "5px";
  document.body.appendChild(el);
} else {
  el = document.getElementById(id);
  redDot = document.getElementById(dotID);
  description = document.getElementById(descID);
}
el.style.top = (rect.top + y) + "px";
el.style.left = (rect.left + x) + "px";
description.innerHTML = "Moved to (x: " + el.style.left + ", y: " + el.style.top + ")";
console.log(x);
console.log(y);
console.log(element);