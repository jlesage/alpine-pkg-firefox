
local ALPINE_REPO = "testing";
local ALPINE_PKG = "firefox";
local GIT_COMMIT = "683ac6232089f61ae559f80fbdbb2467756ca9e7";

local Pipeline(alpine_version) = {
  kind: "pipeline",
  name: "alpine-"+alpine_version,
  workspace: {
    base: "/workspace",
    path: "src"
  },
  steps: [
    {
      name: "prepare",
      image: "alpine",
      commands: [
        "mkdir /workspace/pkg",
      ]
    },
    {
      name: "download",
      image: "byrnedo/alpine-curl",
      commands: [
        "curl -L -o aports.tar.gz https://github.com/alpinelinux/aports/archive/"+GIT_COMMIT+".tar.gz"
      ]
    },
    {
      name: "extract",
      image: "alpine:3.8",
      commands: [
        "apk --no-cache add tar",
        "tar xf aports.tar.gz --wildcards --strip 3 aports-*/"+ALPINE_REPO+"/"+ALPINE_PKG
      ]
    },
    {
      name: "patch",
      image: "alpine",
      commands: [
        "[ ! -f patches/"+alpine_version+".patch ] || patch -p1 -i patches/"+alpine_version+".patch"
      ]
    },
    {
      name: "build",
      image: "jlesage/alpine-abuild:"+alpine_version,
      environment: {
        PKG_SIGNING_KEY: {
          from_secret: "alpine_key"
        },
        PKG_SIGNING_KEY_NAME: "jlesage.rsa",
        PKG_SRC_DIR: "/workspace/src",
        PKG_DST_DIR: "/workspace/pkg"
      },
    },
    {
      name: "publish",
      image: "plugins/github-release",
      settings: {
        api_key: {
          from_secret: "github_token"
        },
        files: [
          "pkg/*.apk"
        ],
        checksum: [
          "md5",
          "sha1",
          "sha256",
          "sha512",
        ]
      },
      when: {
        event: "tag"
      }
    }
  ]
};

[
  Pipeline("3.8"),
  Pipeline("3.9")
]
