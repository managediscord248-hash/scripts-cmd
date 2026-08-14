const OWNER = "managediscord248-hash";
const REPO = "scripts-cmd";
const BRANCH = "main";

const FILES = {
  "/cmd.sh": "cmd.sh",
  "/vm.sh": "vm.sh",
  "/jtg.sh": "jtg.sh",
  "/termius.sh": "termius.sh",
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const file = FILES[url.pathname];

    if (!file) {
      return new Response("Not Found", { status: 404 });
    }

    if (!env.GITHUB_TOKEN) {
      return new Response("GITHUB_TOKEN is not configured", {
        status: 500,
      });
    }

    const apiUrl =
      `https://api.github.com/repos/${OWNER}/${REPO}/contents/` +
      `${file}?ref=${BRANCH}`;

    const githubResponse = await fetch(apiUrl, {
      headers: {
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "scripts-cmd-worker",
      },
    });

    if (!githubResponse.ok) {
      return new Response(
        `GitHub API error: ${githubResponse.status}`,
        { status: 502 }
      );
    }

    const data = await githubResponse.json();

    if (!data.content) {
      return new Response("File content not found", {
        status: 404,
      });
    }

    const binary = atob(data.content.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
    const content = new TextDecoder().decode(bytes);

    return new Response(content, {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store",
      },
    });
  },
};
