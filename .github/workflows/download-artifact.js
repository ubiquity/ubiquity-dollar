export default async function downloadArtifact(github, context, RUN_ID) {
  const artifacts = await github.actions.listWorkflowRunArtifacts({
    owner: context.repo.owner,
    repo: context.repo.repo,
    run_id: RUN_ID,
  });
  const matchArtifact = artifacts.data.artifacts.filter((artifact) => artifact.name == "pr")[0];
  const download = await github.actions.downloadArtifact({
    owner: context.repo.owner,
    repo: context.repo.repo,
    artifact_id: matchArtifact.id,
    archive_format: "zip",
  });
  require("fs").writeFileSync("${{github.workspace}}/pr.zip", Buffer.from(download.data));
}
