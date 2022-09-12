module.exports = async ({ github, context, fs, workflow_run_id, workspace }) => {
  console.log("download_artifact.....");
  console.log({ github, context });
  const artifacts = await github.actions.listWorkflowRunArtifacts({
    owner: context.repo.owner,
    repo: context.repo.repo,
    run_id: workflow_run_id,
  });
  const matchArtifact = artifacts.data.artifacts.filter((artifact) => {
    return artifact.name == "pr";
  })[0];
  const download = await github.actions.downloadArtifact({
    owner: context.repo.owner,
    repo: context.repo.repo,
    artifact_id: matchArtifact.id,
    archive_format: "zip",
  });
  fs.writeFileSync(`${workspace}/pr.zip`, Buffer.from(download.data));
};
