/**
 * Component allows the user to toggle between light and dark mode:
 * @returns JSX template
 */
export default function LightDarkMode() {
  return (
    <div id="LightDarkMode">
      <button id="LightDarkModeToggle" onClick={toggleDarkMode}></button>
    </div>
  );
}

function toggleDarkMode() {
  const body = document.getElementById(`__next`);
  const lightDarkModeToggle = document.getElementById("LightDarkModeToggle");
  const isLightMode = body.classList.contains("light-mode");

  if (isLightMode) {
    body.classList.remove("light-mode");
    lightDarkModeToggle?.classList.remove("active");
  } else {
    body.classList.add("light-mode");
    lightDarkModeToggle?.classList.add("active");
  }
}
