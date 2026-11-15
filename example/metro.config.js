// Metro config for running the example against the library source in `..`.
//
// - `expo-roomplan` resolves straight to ../src, so library edits hot-reload
//   without running `npm run build` first.
// - The repo root has its own copies of react, react-native and expo (dev
//   dependencies of the library). They're blocked so imports from ../src fall
//   through to this app's node_modules; resolving both copies causes
//   "Invalid hook call" and duplicate native module errors.
const path = require("path");
const { getDefaultConfig } = require("expo/metro-config");

const projectRoot = __dirname;
const libraryRoot = path.resolve(projectRoot, "..");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [libraryRoot];

config.resolver.nodeModulesPaths = [path.resolve(projectRoot, "node_modules")];

const escape = (p) => p.replace(/[/\\]/g, "[/\\\\]").replace(/\./g, "\\.");
config.resolver.blockList = [
  ...Array.from(config.resolver.blockList ?? []),
  new RegExp(`^${escape(path.join(libraryRoot, "node_modules"))}[/\\\\].*`),
  new RegExp(`^${escape(path.join(libraryRoot, "build"))}[/\\\\].*`),
];

const librarySource = path.join(libraryRoot, "src", "index.ts");
const defaultResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (moduleName === "expo-roomplan") {
    return { type: "sourceFile", filePath: librarySource };
  }
  return (defaultResolveRequest ?? context.resolveRequest)(
    context,
    moduleName,
    platform
  );
};

module.exports = config;
