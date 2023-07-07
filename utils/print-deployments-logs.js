//@ts-check
module.exports = async ({ github, context, fs }) => {
  const pullRequestInfo = fs.readFileSync("./pr_number").toString("utf-8");
  console.log({ pullRequestInfo });
  const infoSubstring = pullRequestInfo.split(",");
  const eventName = infoSubstring[0].split("=")[1];
  const pullRequestNumber = infoSubstring[1].split("=")[1] ?? 0;
  const commitSha = infoSubstring[2].split("=")[1];
  const deploymentsLog = fs.readFileSync("./deployments.log").toString("utf-8");

  let defaultBody = deploymentsLog;
  const uniqueDeployUrl = deploymentsLog.match(/https:\/\/.+\.pages\.dev/gim);
  const botCommentsArray = [];

  if (uniqueDeployUrl) {
    const slicedSha = commitSha.slice(0, -33);

    defaultBody = `- [${slicedSha}](${uniqueDeployUrl})`;
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
    const sortCommentBody = sortComments(commentBody);
    await createNewPRComment(sortCommentBody);
    await deleteExistingPRComments();
  };

  const processPRComments = async () => {
    const perPage = 30;
    let pageNumber = 1;
    let hasMore = true;
    const commentsArray = [];

    while (hasMore) {
      const { data: issueComments } = await github.rest.issues.listComments({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: pullRequestNumber,
        per_page: perPage,
        page: pageNumber,
      });
      pageNumber++;

      if (issueComments.length > 0) {
        commentsArray.push(...issueComments);
      } else {
        hasMore = false;
      }
    }

    if (commentsArray.length > 0) {
      commentsArray.forEach((elem) => {
        if (elem.user.type === "Bot" && elem.user.login === "ubiquibot[bot]") {
          botCommentsArray.push(elem);
        }
      });
      const botLen = botCommentsArray.length;
      switch (botLen) {
        case 0:
          //no (bot) comments
          createNewPRComment();
          break;
        case 1:
          //single (bot) comment []
          editExistingPRComment();
          break;
        default:
          //multiple (bot) comments []
          mergeExistingPRComments();
          break;
      }
    } else {
      //no comments (user|bot) []
      createNewPRComment();
    }
  };

  if (eventName == "pull_request") {
    console.log("Creating a comment for the pull request");
    await processPRComments();
  } else {
    console.log("Creating a comment for the commit");
    await createNewCommitComment();
  }
};
