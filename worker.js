const FILES = {
  "/cmd.sh": "cmd.sh",
  "/vm.sh": "vm.sh",
  "/jtg.sh": "jtg.sh",
  "/termius.sh": "termius.sh"
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const file = FILES[url.pathname];

    if (!file) {
      return new Response("Not Found", { status: 404 });
    }

    const apiUrl =
      `https://api.github.com/repos/managediscord248-hash/scripts-cmd/contents/${file}?ref=main`;

    const response = await fetch(apiUrl, {
      headers: {
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "Cloudflare-Worker"
      }
    });

    if (!response.ok) {
      return new Response(
        `GitHub error: ${response.status}`,
        { status: response.status }
      );
    }

    const data = await response.json();

    if (!data.content) {
      return new Response("File content not found", { status: 404 });
    }

    const binary = atob(data.content.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));

    return new Response(new TextDecoder().decode(bytes), {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store"
      }
    });
  }
};
