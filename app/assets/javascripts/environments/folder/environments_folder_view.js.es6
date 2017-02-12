/* eslint-disable no-param-reassign, no-new */
/* global Flash */

const Vue = require('vue');
Vue.use(require('vue-resource'));
const EnvironmentsService = require('../services/environments_service');
const EnvironmentTable = require('./environments_table');
const Store = require('../stores/environments_folder_store');
require('../../vue_shared/components/table_pagination');

module.exports = Vue.component('environment-folder-view', {

  components: {
    'environment-table': EnvironmentTable,
    'table-pagination': gl.VueGlPagination,
  },

  props: {
    endpoint: {
      type: String,
      required: true,
      default: '',
    },

    folderName: {
      type: String,
      required: true,
      default: '',
    },
  },

  data() {
    const store = new Store();

    return {
      store,
      state: store.state,
      isLoading: false,

      // Pagination Properties,
      paginationInformation: {},
      pageNumber: 1,
    };
  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    const scope = this.$options.getQueryParameter('scope') || this.visibility;
    const pageNumber = this.$options.getQueryParameter('page') || this.pageNumber;

    const endpoint = `${this.endpoint}?scope=${scope}&page=${pageNumber}`;

    const service = new EnvironmentsService(endpoint);

    this.isLoading = true;

    return service.all()
      .then(resp => ({
        headers: resp.headers,
        body: resp.json(),
      }))
      .then((response) => {
        this.store.storeEnvironments(response.body.environments);
        this.store.storePagination(response.headers);
      })
      .then(() => {
        this.isLoading = false;
      })
      .catch(() => {
        this.isLoading = false;
        new Flash('An error occurred while fetching the environments.', 'alert');
      });
  },

  /**
   * Transforms the url parameter into an object and
   * returns the one requested.
   *
   * @param  {String} param
   * @returns {String}       The value of the requested parameter.
   */
  getQueryParameter(parameter) {
    return window.location.search.substring(1).split('&').reduce((acc, param) => {
      const paramSplited = param.split('=');
      acc[paramSplited[0]] = paramSplited[1];
      return acc;
    }, {})[parameter];
  },

  methods: {
    /**
     * Will change the page number and update the URL.
     *
     * If no search params are present, we'll add param for page
     * If param for page is already present, we'll update it
     * If there are params but none for page, we'll add it at the end.
     *
     * @param  {Number} pageNumber desired page to go to.
     */
    changePage(pageNumber) {
      let param;
      if (window.location.search.length === 0) {
        param = `?page=${pageNumber}`;
      }

      if (window.location.search.indexOf('page') !== -1) {
        param = window.location.search.replace(/page=\d/g, `page=${pageNumber}`);
      }

      if (window.location.search.length &&
        window.location.search.indexOf('page') === -1) {
        param = `${window.location.search}&page=${pageNumber}`;
      }

      gl.utils.visitUrl(param);
      return param;
    },
  },

  template: `
    <div :class="cssContainerClass">
      <div class="top-area">
        <ul v-if="!isLoading" class="nav-links">
          <li v-bind:class="{ 'active': scope === undefined || scope === 'available' }">
            <a :href="projectEnvironmentsPath">
              Available
              <span class="badge js-available-environments-count">
                {{state.availableCounter}}
              </span>
            </a>
          </li>
          <li v-bind:class="{ 'active' : scope === 'stopped' }">
            <a :href="projectStoppedEnvironmentsPath">
              Stopped
              <span class="badge js-stopped-environments-count">
                {{state.stoppedCounter}}
              </span>
            </a>
          </li>
        </ul>
        <div v-if="canCreateEnvironmentParsed && !isLoading" class="nav-controls">
          <a :href="newEnvironmentPath" class="btn btn-create">
            New environment
          </a>
        </div>
      </div>

      <div class="environments-container">
        <div class="environments-list-loading text-center" v-if="isLoading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div class="blank-state blank-state-no-icon"
          v-if="!isLoading && state.environments.length === 0">
          <h2 class="blank-state-title js-blank-state-title">
            You don't have any environments right now.
          </h2>
          <p class="blank-state-text">
            Environments are places where code gets deployed, such as staging or production.
            <br />
            <a :href="helpPagePath">
              Read more about environments
            </a>
          </p>

          <a v-if="canCreateEnvironmentParsed"
            :href="newEnvironmentPath"
            class="btn btn-create js-new-environment-button">
            New Environment
          </a>
        </div>

        <div class="table-holder"
          v-if="!isLoading && state.environments.length > 0">

          <environment-table
            :environments="state.environments"
            :can-create-deployment="canCreateDeploymentParsed"
            :can-read-environment="canReadEnvironmentParsed"
            :play-icon-svg="playIconSvg"
            :terminal-icon-svg="terminalIconSvg"
            :commit-icon-svg="commitIconSvg">
          </environment-table>

          <table-pagination v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
            :change="changePage"
            :pageInfo="state.paginationInformation">
          </table-pagination>
        </div>
      </div>
    </div>
  `,
});
