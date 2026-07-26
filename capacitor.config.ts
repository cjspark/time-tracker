import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.cjspark.annuli',
  appName: 'Annuli',
  webDir: 'out',
  ios: {
    contentInset: 'always',
  },
  plugins: {
    CapacitorHttp: {
      enabled: false,
    },
  },
};

export default config;
