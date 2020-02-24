import * as types from './mutation_types';

export default {
  [types.REQUEST_SYNC_NAMESPACES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_SYNC_NAMESPACES_SUCCESS](state, data) {
    state.isLoading = false;
    state.synchronizationNamespaces = data;
  },
  [types.RECEIVE_SYNC_NAMESPACES_ERROR](state) {
    state.isLoading = false;
    state.synchronizationNamespaces = [];
  },
  [types.REQUEST_CREATE_GEO_NODE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_CREATE_GEO_NODE_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_CREATE_GEO_NODE_ERROR](state) {
    state.isLoading = false;
  },
  [types.REQUEST_UPDATE_GEO_NODE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_UPDATE_GEO_NODE_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_UPDATE_GEO_NODE_ERROR](state) {
    state.isLoading = false;
  },
};
