import * as types from './mutation_types';

export default {
  [types.SET_EXTERNAL_DASHBOARD_URL](state, url) {
    state.externalDashboard.url = url;
  },
  [types.SET_DASHBOARD_TIMEZONE_SETTING](state, setting) {
    state.dashboardTimezone.setting = setting;
  },
};
