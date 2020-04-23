import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import store from './store';
import AlertManagementList from './components/alert_management_list.vue';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-alert_management';

  const domEl = document.querySelector(selector);
  const { indexPath, enableAlertManagementPath, emptyAlertSvgPath } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: selector,
    apolloProvider,
    components: {
      AlertManagementList,
    },
    store,
    render(createElement) {
      return createElement('alert-management-list', {
        props: {
          indexPath,
          enableAlertManagementPath,
          emptyAlertSvgPath,
        },
      });
    },
  });
};
