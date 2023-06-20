/**
 * Component allows the user to toggle between light and dark mode:
 * @returns JSX template
 */
export default function LightDarkMode() {
  return (
    <div id="light-dark-mode">
      <button id="LightDarkModeToggle" onClick={toggleDarkMode}></button>
    </div>
  );
}

function toggleDarkMode() {
  const __next = document.getElementById(`__next`);
  if (!__next) {
    throw new Error("Could not find '__next' element");
  }
  const lightDarkModeToggle = document.getElementById("LightDarkModeToggle");
  const isLightMode = __next.classList.contains("light-mode");

  if (isLightMode) {
    __next.classList.remove("light-mode");
    lightDarkModeToggle?.classList.remove("active");
  } else {
    __next.classList.add("light-mode");
    lightDarkModeToggle?.classList.add("active");
  }
}
