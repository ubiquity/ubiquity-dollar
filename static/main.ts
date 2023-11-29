export async function mainModule() {
  console.log(`Hello from mainModule`);
}
mainModule()
  .then(() => {
    console.log("mainModule loaded");
  })
  .catch((error) => {
    console.error(error);
  });
