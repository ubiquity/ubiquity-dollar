module.exports = async ({ github, context, fs }) => {
  const pullRequestInfo = fs.readFileSync("./pr_number").toString("utf-8");
  console.log({ pullRequestInfo });
  const infoSubstring = pullRequestInfo.split(",");
  const eventName = infoSubstring[0].split("=")[1];
  const pullRequestNumber = infoSubstring[1].split("=")[1] ?? 0;
  const commitSha = infoSubstring[2].split("=")[1];
  const deploymentsLog = fs.readFileSync("./deployments.log").toString("utf-8");

  let body = deploymentsLog;
  const uniqueDeployUrl = deploymentsLog.match(/https:\/\/.+\.netlify\.app/gim);

  if (uniqueDeployUrl) {
    body = `[Deployment: ${new Date()}](${uniqueDeployUrl})`;
  }

  if (eventName == "pull_request") {
    console.log("Creating a comment for the pull request");
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: pullRequestNumber,
      body,
    });
  } else {
    console.log("Creating a comment for the commit");

    await github.rest.repos.createCommitComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      commit_sha: commitSha,
      body,
    });
  }
};
