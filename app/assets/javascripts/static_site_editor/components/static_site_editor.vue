<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlSkeletonLoader } from '@gitlab/ui';

import EditArea from './edit_area.vue';
import EditHeader from './edit_header.vue';
import Toolbar from './publish_toolbar.vue';

export default {
  components: {
    EditArea,
    EditHeader,
    GlSkeletonLoader,
    Toolbar,
  },
  computed: {
    ...mapState([
      'content',
      'isLoadingContent',
      'isSavingChanges',
      'isContentLoaded',
      'returnUrl',
      'title',
    ]),
    ...mapGetters(['contentChanged']),
  },
  mounted() {
    this.loadContent();
  },
  methods: {
    ...mapActions(['loadContent', 'setContent', 'submitChanges']),
  },
};
</script>
<template>
  <div class="d-flex justify-content-center h-100 pt-2">
    <div v-if="isLoadingContent" class="w-50 h-50">
      <gl-skeleton-loader :width="500" :height="102">
        <rect width="500" height="16" rx="4" />
        <rect y="20" width="375" height="16" rx="4" />
        <rect x="380" y="20" width="120" height="16" rx="4" />
        <rect y="40" width="250" height="16" rx="4" />
        <rect x="255" y="40" width="150" height="16" rx="4" />
        <rect x="410" y="40" width="90" height="16" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div v-if="isContentLoaded" class="d-flex flex-grow-1 flex-column">
      <edit-header class="w-75 align-self-center py-2" :title="title" />
      <edit-area
        class="w-75 h-100 shadow-none align-self-center"
        :value="content"
        @input="setContent"
      />
      <toolbar
        :return-url="returnUrl"
        :saveable="contentChanged"
        :saving-changes="isSavingChanges"
        @submit="submitChanges"
      />
    </div>
  </div>
</template>
