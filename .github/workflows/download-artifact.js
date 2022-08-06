export default async function downloadArtifact(github, context, run_id) {
  var artifacts = await github.actions.listWorkflowRunArtifacts({
    owner: context.repo.owner,
    repo: context.repo.repo,
    run_id: run_id,
  });
  var matchArtifact = artifacts.data.artifacts.filter((artifact) => {
    return artifact.name == "pr";
  })[0];
  var download = await github.actions.downloadArtifact({
    owner: context.repo.owner,
    repo: context.repo.repo,
    artifact_id: matchArtifact.id,
    archive_format: "zip",
  });
  var fs = require("fs");
  fs.writeFileSync("${{github.workspace}}/pr.zip", Buffer.from(download.data));
}
