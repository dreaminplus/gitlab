import { shallowMount } from '@vue/test-utils';
import AlertsSettingsForm from '~/incidents_settings/components/alerts_form.vue';

describe('Alert integration settings form', () => {
  let wrapper;
  const service = { updateSettings: jest.fn().mockResolvedValue() };

  const findForm = () => wrapper.find({ ref: 'settingsForm' });

  beforeEach(() => {
    wrapper = shallowMount(AlertsSettingsForm, {
      provide: {
        service,
        alertSettings: {
          issueTemplateKey: 'selecte_tmpl',
          createIssue: true,
          sendEmail: false,
          templates: [],
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('default state', () => {
    it('should match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('form', () => {
    it('should call service `updateSettings` on submit', () => {
      findForm().trigger('submit');
      expect(service.updateSettings).toHaveBeenCalledWith(
        expect.objectContaining({ settingsKey: 'incident_management_setting_attributes' }),
      );
    });
  });
});
