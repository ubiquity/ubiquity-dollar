module.exports = async ({ github, context, fs }) => {
  const pr_info = fs.readFileSync("./pr_number").toString("utf-8");
  console.log({ pr_info });
  const substrs = pr_info.split(",");
  const event_name = substrs[0].split("=")[1];
  const pr_number = substrs[1].split("=")[1] ?? 0;
  const commit_sha = substrs[2].split("=")[1];
  const deployments_log = fs.readFileSync("./deployments.log").toString("utf-8");

  if (event_name == "pull_request") {
    console.log("Creating a comment for the pull request");
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: pr_number,
      body: deployments_log,
    });
  } else {
    console.log("Creating a comment for the commit");
    await github.rest.repos.createCommitComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      commit_sha: commit_sha,
      body: deployments_log,
    });
  }
};
