//@ts-check
module.exports = async ({ github, context, fs }) => {
  const { payload } = context;
  const eventName = context.eventName;
  const pullRequestNumber = eventName === 'pull_request' ? payload.pull_request.number : 0;
  const commitSha = payload.after;
  const deploymentsLog = fs.readFileSync("./deployments.log").toString("utf-8");

  let defaultBody = deploymentsLog;
  const uniqueDeployUrl = deploymentsLog.match(/https:\/\/.+\.netlify\.app/gim);
  const botCommentsArray = [];

  console.log("test is displayed");

  if (uniqueDeployUrl) {
    defaultBody = `[Deployment: ${new Date()}](${uniqueDeployUrl})`;
  }

  const verifyInput = (data) => {
    return data !== "";
  };

  const GMTConverter = (bodyData) => {
    return bodyData.replace("GMT+0000 (Coordinated Universal Time)", "(UTC)");
  };

  const sortComments = (bodyData) => {
    const bodyArray = bodyData.split("\n").filter((elem) => elem.includes("Deployment"));
    let commentBody = ``;
    const timeArray = [];
    const timeObj = {};
    bodyArray.forEach((element) => {
      const timestamp = new Date(
          element
              .match(/Deployment:.*\(UTC\)/)[0]
              .replace("Deployment:", "")
              .trim()
      ).getTime();
      timeArray.push(timestamp);
      timeObj[timestamp] = element;
    });
    const timeSortArray = timeArray.sort();

    timeSortArray.forEach((em) => {
      commentBody = commentBody + `${timeObj[em]}\n`;
    });
    return commentBody;
  };

  const createNewCommitComment = async (body = defaultBody) => {
    body = GMTConverter(body);
    verifyInput(body) &&
    (await github.rest.repos.createCommitComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      commit_sha: commitSha,
      body: body,
    }));
  };

  const createNewPRComment = async (body = defaultBody) => {
    body = GMTConverter(body);
    verifyInput(body) &&
    (await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: pullRequestNumber,
      body: body,
    }));
  };

  const editExistingPRComment = async () => {
    const { body: botBody, id: commentId } = botCommentsArray[0];
    let commentBody = `${GMTConverter(defaultBody)}\n` + `${GMTConverter(botBody)}`;
    const sortCommentBody = sortComments(commentBody);
    verifyInput(sortCommentBody) &&
    (await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: commentId,
      body: sortCommentBody,
    }));
  };

  const deleteExistingPRComments = async () => {
    const delPromises = botCommentsArray.map(async (elem) => {
      await github.rest.issues.deleteComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        comment_id: elem.id,
      });
    });
    await Promise.all(delPromises);
  };

  const mergeExistingPRComments = async () => {
    let commentBody = `${GMTConverter(defaultBody)}\n`;
    botCommentsArray.forEach(({ body }) => {
      commentBody = commentBody + `${GMTConverter(body)}\n`;
    });
    const sortCommentBody = sortComments
