module.exports = {
    env: {
        // COMMIT_REF is populated by netlify on project build
        NEXT_PUBLIC_COMMIT_REF: process.env.COMMIT_REF,
    },
}