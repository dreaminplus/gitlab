<script>
import { issueHealthStatus, issueHealthStatusCSSMapping } from '../constants';

export default {
  props: {
    healthStatus: {
      type: String,
      required: true,
      default: '',
    },
  },
  computed: {
    getFormattedStatus() {
      return issueHealthStatus[this.healthStatus];
    },

    cssMapping() {
      return issueHealthStatusCSSMapping[this.healthStatus];
    },
  },
};
</script>

<template>
  <div class="health-status d-inline-flex align-items-center">
    <span class="gl-label gl-label-text-dark gl-label-sm" :class="cssMapping">
      <span class="gl-label-text">
        {{ getFormattedStatus }}
      </span>
    </span>
  </div>
</template>
