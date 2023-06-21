/**
 * Component renders build info details:
 * - commit hash URL
 * @returns JSX template
 */
export default function BuildInfo() {
  return (
    <div id="BuildInfo">
      <a href={`https://github.com/ubiquity/ubiquity-dollar/commit/${process.env.GIT_COMMIT_REF}`} target="_blank" rel="noopener noreferrer">
        Build {process.env.GIT_COMMIT_REF}
      </a>
    </div>
  );
}
