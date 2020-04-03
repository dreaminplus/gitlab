import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import FirstClassProjectDashboard from './components/first_class_project_dashboard.vue';
import FirstClassGroupDashboard from './components/first_class_group_dashboard.vue';

const isRequired = message => {
  throw new Error(message);
};

export default (
  /* eslint-disable @gitlab/require-i18n-strings */
  el = isRequired('No element was passed to the security dashboard initializer'),
  dashboardType = isRequired('No dashboard type was passed to the security dashboard initializer'),
  /* eslint-enable @gitlab/require-i18n-strings */
) => {
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  const { dashboardDocumentation, emptyStateSvgPath } = el.dataset;
  const props = {
    emptyStateSvgPath,
    dashboardDocumentation,
  };
  let element;

  // We'll add more of these for group and instance once we have the components
  if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    element = FirstClassProjectDashboard;
    props.projectFullPath = el.dataset.projectFullPath;
  } else if (dashboardType === DASHBOARD_TYPES.GROUP) {
    element = FirstClassGroupDashboard;
    props.groupFullPath = el.dataset.groupFullPath;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(element, { props });
    },
  });
};
