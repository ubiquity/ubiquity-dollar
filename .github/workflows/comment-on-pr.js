const fs = require("fs");
export default async function commentOnPr(github, context) {
  const issue_number = Number(fs.readFileSync("./pr_number"));
  const deployments_log = fs.readFileSync("./deployments.log");
  return await github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: issue_number,
    body: deployments_log.toString(),
  });
}
