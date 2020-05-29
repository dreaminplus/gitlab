import Vue from 'vue';
import IdeRouter from '~/ide/ide_router_extension';
import { joinPaths } from '~/lib/utils/url_utility';
import flash from '~/flash';
import { __ } from '~/locale';

Vue.use(IdeRouter);

/**
 * Routes below /-/ide/:

/project/h5bp/html5-boilerplate/blob/master
/project/h5bp/html5-boilerplate/blob/master/app/js/test.js

/project/h5bp/html5-boilerplate/mr/123
/project/h5bp/html5-boilerplate/mr/123/app/js/test.js

/workspace/123
/workspace/project/h5bp/html5-boilerplate/blob/my-special-branch
/workspace/project/h5bp/html5-boilerplate/mr/123

/ = /workspace

/settings
*/

// Unfortunately Vue Router doesn't work without at least a fake component
// If you do only data handling
const EmptyRouterComponent = {
  render(createElement) {
    return createElement('div');
  },
};

// eslint-disable-next-line import/prefer-default-export
export const createRouter = store => {
  let currentPath = null;

  const router = new IdeRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', '/-/ide/'),
    routes: [
      {
        path: '/project/:namespace+/:project',
        component: EmptyRouterComponent,
        children: [
          {
            path: ':targetmode(edit|tree|blob)/:branchid+/-/*',
            component: EmptyRouterComponent,
          },
          {
            path: ':targetmode(edit|tree|blob)/:branchid+/',
            redirect: to => joinPaths(to.path, '/-/'),
          },
          {
            path: ':targetmode(edit|tree|blob)',
            redirect: to => joinPaths(to.path, '/master/-/'),
          },
          {
            path: 'merge_requests/:mrid',
            component: EmptyRouterComponent,
          },
          {
            path: '',
            redirect: to => joinPaths(to.path, '/edit/master/-/'),
          },
        ],
      },
    ],
  });

  // sync store to router
  store.watch(
    state => state.router.fullPath,
    fullPath => {
      if (currentPath === fullPath) {
        return;
      }

      currentPath = fullPath;
      router.push(fullPath);
    },
  );

  // sync router to store
  router.afterEach(to => {
    currentPath = to.fullPath;
    store.dispatch('router/push', currentPath, { root: true });
  });

  router.beforeEach((to, from, next) => {
    if (to.params.namespace && to.params.project) {
      store
        .dispatch('getProjectData', {
          namespace: to.params.namespace,
          projectId: to.params.project,
        })
        .then(() => {
          const basePath = to.params.pathMatch || '';
          const projectId = `${to.params.namespace}/${to.params.project}`;
          const branchId = to.params.branchid;
          const mergeRequestId = to.params.mrid;

          if (branchId) {
            store.dispatch('openBranch', {
              projectId,
              branchId,
              basePath,
            });
          } else if (mergeRequestId) {
            store.dispatch('openMergeRequest', {
              projectId,
              mergeRequestId,
              targetProjectId: to.query.target_project,
            });
          }
        })
        .catch(e => {
          flash(
            __('Error while loading the project data. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          throw e;
        });
    }

    next();
  });

  return router;
};
