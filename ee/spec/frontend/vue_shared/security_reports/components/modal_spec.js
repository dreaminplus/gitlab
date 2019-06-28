import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createState from 'ee/vue_shared/security_reports/store/state';
import { mount, shallowMount } from '@vue/test-utils';

describe('Security Reports modal', () => {
  const Component = Vue.extend(component);
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.isDismissed = true;
        propsData.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
        };
        wrapper = mount(Component, { propsData });
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(wrapper.text().trim()).toContain('John Smith');
        expect(wrapper.text().trim()).toContain('@jsmith');
        expect(wrapper.text().trim()).toContain('#123');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        wrapper = mount(Component, { propsData });
      });

      it('renders the footer', () => {
        expect(wrapper.classes('modal-hide-footer')).toBe(false);
      });
    });

    describe('with merge request available', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canCreateIssue: true,
          canCreateMergeRequest: true,
        };
        const summary = 'Upgrade to 123';
        const diff = 'abc123';
        propsData.modal.vulnerability.remediations = [{ summary, diff }];
        wrapper = mount(Component, { propsData, sync: true });
      });

      it('renders create merge request and issue button as a split button', () => {
        expect(wrapper.contains('.js-split-button')).toBe(true);
        expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
        expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
      });

      describe('with merge request created', () => {
        it('renders the issue button as a single button', done => {
          const propsData = {
            modal: createState().modal,
            canCreateIssue: true,
            canCreateMergeRequest: true,
          };

          propsData.modal.vulnerability.hasMergeRequest = true;

          wrapper.setProps(propsData);

          Vue.nextTick()
            .then(() => {
              expect(wrapper.contains('.js-split-button')).toBe(false);
              expect(wrapper.contains('.js-action-button')).toBe(true);
              expect(wrapper.find('.js-action-button').text()).not.toContain(
                'Resolve with merge request',
              );
              expect(wrapper.find('.js-action-button').text()).toContain('Create issue');
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        propsData.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        wrapper = mount(Component, { propsData });
      });

      it('renders title', () => {
        expect(wrapper.text()).toContain('Arbitrary file existence disclosure in Action Pack');
      });

      it('renders help link', () => {
        expect(wrapper.find('.js-link-vulnerabilityFeedbackHelpPath').attributes('href')).toBe(
          'feedbacksHelpPath#solutions-for-vulnerabilities',
        );
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      wrapper = shallowMount(Component, { propsData });
    });

    it('does not display the footer', () => {
      expect(wrapper.classes('modal-hide-footer')).toBe(true);
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.isResolved = true;
      wrapper = shallowMount(Component, { propsData });
    });

    it('does not display the footer', () => {
      expect(wrapper.classes('modal-hide-footer')).toBe(true);
    });
  });

  describe('Vulnerability Details', () => {
    const blobPath = '/group/project/blob/1ab2c3d4e5/some/file.path#L0-0';
    const namespaceValue = 'foobar';
    const fileValue = '/some/file.path';

    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.vulnerability.blob_path = blobPath;
      propsData.modal.data.namespace.value = namespaceValue;
      propsData.modal.data.file.value = fileValue;
      wrapper = mount(Component, { propsData });
    });

    it('is rendered', () => {
      const vulnerabilityDetails = wrapper.find('.js-vulnerability-details');

      expect(vulnerabilityDetails.exists()).toBe(true);
      expect(vulnerabilityDetails.text()).toContain('foobar');
    });

    it('computes valued fields properly', () => {
      expect(wrapper.vm.valuedFields).toMatchObject({
        file: {
          value: fileValue,
          url: blobPath,
          isLink: true,
          text: 'File',
        },
        namespace: {
          value: namespaceValue,
          text: 'Namespace',
          isLink: false,
        },
      });
    });
  });

  describe('Solution Card', () => {
    it('is rendered if the vulnerability has a solution', () => {
      const propsData = {
        modal: createState().modal,
      };

      const solution = 'Upgrade to XYZ';
      propsData.modal.vulnerability.solution = solution;
      wrapper = mount(Component, { propsData });

      const solutionCard = wrapper.find('.js-solution-card');

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(solution);
      expect(wrapper.contains('hr')).toBe(false);
    });

    it('is rendered if the vulnerability has a remediation', () => {
      const propsData = {
        modal: createState().modal,
      };
      const summary = 'Upgrade to 123';
      propsData.modal.vulnerability.remediations = [{ summary }];
      wrapper = mount(Component, { propsData });

      const solutionCard = wrapper.find('.js-solution-card');

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(summary);
      expect(wrapper.contains('hr')).toBe(false);
    });

    it('is rendered if the vulnerability has neither a remediation nor a solution', () => {
      const propsData = {
        modal: createState().modal,
      };
      wrapper = mount(Component, { propsData });

      const solutionCard = wrapper.find('.js-solution-card');

      expect(solutionCard.exists()).toBe(true);
      expect(wrapper.contains('hr')).toBe(false);
    });
  });
});
