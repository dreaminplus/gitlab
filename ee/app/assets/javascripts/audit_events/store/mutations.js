import * as types from './mutation_types';

export default {
  [types.INITIALIZE_AUDIT_EVENTS](
    state,
    {
      entity_id: id = null,
      entity_type: type = null,
      created_after: startDate = null,
      created_before: endDate = null,
      sort: sortBy = null,
    } = {},
  ) {
    state.filterValue = { id, type };
    state.startDate = startDate;
    state.endDate = endDate;
    state.sortBy = sortBy;
  },

  [types.SET_FILTER_VALUE](state, { id, type }) {
    state.filterValue = { id, type };
  },

  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },

  [types.SET_SORT_BY](state, sortBy) {
    state.sortBy = sortBy;
  },
};
