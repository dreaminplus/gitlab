import Vue from 'vue';
import VulnerabilitiesApp from 'ee/vulnerabilities/components/vulnerabilities_app.vue';
import createDefaultClient from '~/lib/graphql';
import VueApollo from 'vue-apollo';

Vue.use(VueApollo);

function render() {
  const el = document.getElementById('app');

  if (!el) {
    return false;
  }

  const { dashboardDocumentation, emptyStateSvgPath, projectFullPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(VulnerabilitiesApp, {
        props: {
          emptyStateSvgPath,
          dashboardDocumentation,
          projectFullPath,
        },
      });
    },
  });
}

window.addEventListener('DOMContentLoaded', () => {
  render();
});
