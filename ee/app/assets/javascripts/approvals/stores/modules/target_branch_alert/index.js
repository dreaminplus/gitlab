import createState from './state';
import * as actions from './actions';
import mutations from './mutations';

export default () => ({
  // namespaced: true,
  state: createState(),
  actions,
  mutations,
});
