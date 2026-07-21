// Expo config plugin for expo-roomplan
// - Ensures NSCameraUsageDescription is set
// - Raises Podfile iOS platform to 16.0 (minimum required by RoomPlan)
// The Privacy Manifest is embedded via the podspec resources.

const {
  withInfoPlist,
  withPodfile,
  createRunOncePlugin,
} = require("expo/config-plugins");
const pkg = require("./package.json");

const DEFAULT_CAMERA_DESC =
  "Allow camera access to scan rooms using Apple RoomPlan.";

function withCameraPermission(config, cameraPermissionText) {
  return withInfoPlist(config, (config) => {
    const infoPlist = config.modResults;
    if (!infoPlist.NSCameraUsageDescription) {
      infoPlist.NSCameraUsageDescription =
        cameraPermissionText || DEFAULT_CAMERA_DESC;
    }
    return config;
  });
}

function coerceVersionNumber(v) {
  if (!v) return NaN;
  const num = parseFloat(String(v));
  return Number.isNaN(num) ? NaN : num;
}

function withIosPlatform16(config) {
  return withPodfile(config, (config) => {
    try {
      let contents = config.modResults.contents || "";
      const platformNumericRegex = /^\s*platform\s*:ios,\s*'([0-9.]+)'/m;
      const anyPlatformLineRegex = /^\s*platform\s*:ios,/m;
      const numericMatch = contents.match(platformNumericRegex);
      if (numericMatch) {
        const current = coerceVersionNumber(numericMatch[1]);
        if (!Number.isNaN(current) && current < 16) {
          contents = contents.replace(
            platformNumericRegex,
            "platform :ios, '16.0'"
          );
        }
      } else if (anyPlatformLineRegex.test(contents)) {
        // There's already a platform line (possibly dynamic via podfile_properties). Don't insert another.
        // Rely on expo-build-properties or user config to set >= 16.0.
      } else {
        // Prepend platform line at the top of Podfile when none exists at all
        contents = `platform :ios, '16.0'\n` + contents;
      }
      config.modResults.contents = contents;
    } catch (e) {
      console.warn(
        "expo-roomplan: failed to ensure Podfile platform iOS 16.0 —",
        e
      );
    }
    return config;
  });
}

const withExpoRoomplan = (config, props = {}) => {
  const { cameraPermissionText } = props;

  // Add camera usage description
  config = withCameraPermission(config, cameraPermissionText);

  // Ensure Podfile iOS platform is 16.0
  config = withIosPlatform16(config);

  // Privacy manifests: prefer configuring via app.json ios.privacyManifests in the consuming app.

  // Advisory: warn if project ios.deploymentTarget is < 16.0
  const target = config.ios?.deploymentTarget;
  const asNum = coerceVersionNumber(target);
  if (target && !Number.isNaN(asNum) && asNum < 16) {
    console.warn(
      `expo-roomplan: ios.deploymentTarget is ${target} but RoomPlan requires 16.0+. Consider setting "ios.deploymentTarget": "16.0" in app.json/app.config.`
    );
  }

  return config;
};

module.exports = createRunOncePlugin(
  withExpoRoomplan,
  "expo-roomplan",
  pkg.version
);
