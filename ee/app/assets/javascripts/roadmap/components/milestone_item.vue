<script>
import { GlPopover } from '@gitlab/ui';
import CommonMixin from '../mixins/common_mixin';
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';
import { TIMELINE_CELL_MIN_WIDTH, SCROLL_BAR_SIZE } from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  components: {
    GlPopover,
  },
  mixins: [CommonMixin, QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    milestone: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      hoverStyles: {},
    };
  },
  computed: {
    startDateValues() {
      const { startDate } = this.milestone;

      return {
        day: startDate.getDay(),
        date: startDate.getDate(),
        month: startDate.getMonth(),
        year: startDate.getFullYear(),
        time: startDate.getTime(),
      };
    },
    endDateValues() {
      const { endDate } = this.milestone;

      return {
        day: endDate.getDay(),
        date: endDate.getDate(),
        month: endDate.getMonth(),
        year: endDate.getFullYear(),
        time: endDate.getTime(),
      };
    },
    hasStartDate() {
      if (this.presetTypeQuarters) {
        return this.hasStartDateForQuarter();
      } else if (this.presetTypeMonths) {
        return this.hasStartDateForMonth();
      } else if (this.presetTypeWeeks) {
        return this.hasStartDateForWeek();
      }
      return false;
    },
    startDate() {
      return this.milestone.startDateOutOfRange
        ? this.milestone.originalStartDate
        : this.milestone.startDate;
    },
    endDate() {
      return this.milestone.endDateOutOfRange
        ? this.milestone.originalEndDate
        : this.milestone.endDate;
    },
    smallClass() {
      const smallStyleClass = 'milestone-small';
      const minimumStyleClass = 'milestone-minimum';
      if (this.presetTypeQuarters) {
        const width = this.getTimelineBarWidthForQuarters(this.milestone);
        if (width < 9) {
          return minimumStyleClass;
        }
        if (width < 12) {
          return smallStyleClass;
        }
      } else if (this.presetTypeMonths) {
        const width = this.getTimelineBarWidthForMonths();
        if (width < 12) {
          return smallStyleClass;
        }
      }
      return '';
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.hoverStyles = this.getHoverStyles();
    });
  },
  methods: {
    getHoverStyles() {
      const elHeight = this.$root.$el.getBoundingClientRect().y;
      return {
        height: `calc(100vh - ${elHeight + SCROLL_BAR_SIZE}px)`,
      };
    },
  },
};
</script>

<template>
  <div class="timeline-bar-wrapper">
    <span
      v-if="hasStartDate"
      :class="[
        {
          'start-date-undefined': milestone.startDateUndefined,
          'end-date-undefined': milestone.endDateUndefined,
        },
        smallClass,
      ]"
      :style="timelineBarStyles(milestone)"
      class="milestone-item-details d-inline-block position-absolute"
    >
      <a :href="milestone.webPath" class="milestone-url d-block">
        <span
          :id="`milestone-item-${milestone.id}`"
          class="milestone-item-title str-truncated-100 bold position-sticky"
          >{{ milestone.title }}</span
        >
        <span class="timeline-bar position-relative d-block"></span>
      </a>
      <div class="milestone-start-and-end position-relative" :style="hoverStyles"></div>
      <gl-popover
        :target="`milestone-item-${milestone.id}`"
        boundary="viewport"
        placement="lefttop"
        triggers="hover"
        :title="milestone.title"
      >
        {{ timeframeString(milestone) }}
      </gl-popover>
    </span>
  </div>
</template>
