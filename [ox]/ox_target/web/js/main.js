import { createOptions } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;
const eye = document.getElementById("eyeSvg");

window.addEventListener("message", (event) => {
  optionsWrapper.innerHTML = "";

  switch (event.data.event) {
    case "visible": {
      if (event.data.state) {
        body.style.visibility = "visible";
        body.style.opacity = "1";
      } else {
        body.style.opacity = "0";
        body.addEventListener(
          "transitionend",
          () => {
            if (body.style.opacity === "0") {
              body.style.visibility = "hidden";
            }
          },
          { once: true }
        );
      }
      break;
    }
    case "setTarget": {
      eye.classList.add("eye-hover");

      if (event.data.options) {
        for (const type in event.data.options) {
          event.data.options[type].forEach((data, id) => {
            createOptions(type, data, id + 1);
          });
        }
      }

      if (event.data.zones) {
        for (let i = 0; i < event.data.zones.length; i++) {
          event.data.zones[i].forEach((data, id) => {
            createOptions("zones", data, id + 1, i + 1);
          });
        }
      }
    }
  }
});

window.addEventListener('DOMContentLoaded', async () => {
  let primaryColor = await fetchNui('getConfigValue', 'primaryColor');
  let targetIcon = await fetchNui('getConfigValue', 'targetIcon');

  if (!primaryColor || primaryColor.trim() === '') {
    primaryColor = '#BEEE11';
  }

  if (!targetIcon || targetIcon.trim() === '') {
    targetIcon = 'fas fa-share';
  }

  document.documentElement.style.setProperty('--color-primary', primaryColor);

  const eyeElement = document.getElementById('shareIcon');
  if (eyeElement) {
    eyeElement.className = targetIcon;
  }
});
