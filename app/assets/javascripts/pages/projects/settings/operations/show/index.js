import mountErrorTrackingForm from '~/error_tracking_settings';
import mountOperationSettings from '~/operation_settings';
import mountGrafanaIntegration from '~/grafana_integration';
import initSettingsPanels from '~/settings_panels';
import mountStatusPageForm from '~/status_page_settings';

document.addEventListener('DOMContentLoaded', () => {
  mountErrorTrackingForm();
  mountOperationSettings();
  mountGrafanaIntegration();
  initSettingsPanels();
  mountStatusPageForm();
});
