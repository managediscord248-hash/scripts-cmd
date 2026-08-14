export default {
  async fetch(request) {
    const url = new URL(request.url);

    const files = {
      "/cmd.sh": "https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/main/cmd.sh",
      "/vm.sh": "https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/main/vm.sh",
      "/jtg.sh": "https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/main/jtg.sh",
      "/termius.sh": "https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/main/termius.sh"
    };

    if (!files[url.pathname]) {
      return new Response("Not Found", { status: 404 });
    }

    return fetch(files[url.pathname]);
  }
};
