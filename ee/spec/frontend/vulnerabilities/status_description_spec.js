import { mount } from '@vue/test-utils';
import { GlLink, GlSkeletonLoading, GlLoadingIcon } from '@gitlab/ui';
import { capitalize } from 'lodash';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import StatusText from 'ee/vulnerabilities/components/status_description.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

const NON_DETECTED_STATES = Object.keys(VULNERABILITY_STATE_OBJECTS);
const ALL_STATES = ['detected', ...NON_DETECTED_STATES];

describe('Vulnerability status description component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const timeAgo = () => wrapper.find(TimeAgoTooltip);
  const pipelineLink = () => wrapper.find(GlLink);
  const userAvatar = () => wrapper.find(UserAvatarLink);
  const userLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const skeletonLoader = () => wrapper.find(GlSkeletonLoading);

  // Create a date using the passed-in string, or just use the current time if nothing was passed in.
  const createDate = value => (value ? new Date(value) : new Date()).toISOString();

  const createWrapper = ({
    vulnerability = {},
    pipeline = {},
    user,
    isLoadingVulnerability = false,
    isLoadingUser = false,
  } = {}) => {
    const v = vulnerability;
    const p = pipeline;

    // Automatically create the ${v.state}_at property if it doesn't exist. Otherwise, every test would need to create
    // it manually for the component to mount properly.
    if (v.state === 'detected') {
      p.created_at = p.created_at || createDate();
    } else {
      const propertyName = `${v.state}_at`;
      v[propertyName] = v[propertyName] || createDate();
    }

    wrapper = mount(StatusText, {
      propsData: { vulnerability, pipeline, user, isLoadingVulnerability, isLoadingUser },
    });
  };

  describe('state text', () => {
    it.each(ALL_STATES)('shows the correct string for the vulnerability state "%s"', state => {
      createWrapper({ vulnerability: { state } });

      expect(wrapper.text()).toMatch(new RegExp(`^${capitalize(state)}`));
    });
  });

  describe('time ago', () => {
    it('uses the pipeline created date when the vulnerability state is "detected"', () => {
      const pipelineDateString = createDate('2001');
      createWrapper({
        vulnerability: { state: 'detected' },
        pipeline: { created_at: pipelineDateString },
      });

      expect(timeAgo().props('time')).toBe(pipelineDateString);
    });

    // The .map() is used to output the correct test name by doubling up the parameter, i.e. 'detected' -> ['detected', 'detected'].
    it.each(NON_DETECTED_STATES.map(x => [x, x]))(
      'uses the "%s_at" property when the vulnerability state is "%s"',
      state => {
        const expectedDate = createDate();
        createWrapper({
          vulnerability: { state, [`${state}_at`]: expectedDate },
          pipeline: { created_at: 'pipeline_created_at' },
        });

        expect(timeAgo().props('time')).toBe(expectedDate);
      },
    );
  });

  describe('pipeline link', () => {
    it('shows the pipeline link when the vulnerability state is "detected"', () => {
      createWrapper({
        vulnerability: { state: 'detected' },
        pipeline: { url: 'pipeline/url' },
      });

      expect(pipelineLink().attributes('href')).toBe('pipeline/url');
    });

    it.each(NON_DETECTED_STATES)(
      'does not show the pipeline link when the vulnerability state is "%s"',
      state => {
        createWrapper({
          vulnerability: { state },
          pipeline: { url: 'pipeline/url' },
        });

        expect(pipelineLink().exists()).toBe(false); // The user avatar should be shown instead, those tests are handled separately.
      },
    );
  });

  describe('user', () => {
    it('shows a loading icon when the user is loading', () => {
      createWrapper({
        vulnerability: { state: 'dismissed' },
        isLoadingUser: true,
        user: UsersMockHelper.createRandomUser(), // Create a user so we can verify that the loading icon and the user is not shown at the same time.
      });

      expect(userLoadingIcon().exists()).toBe(true);
      expect(userAvatar().exists()).toBe(false);
    });

    it('shows the user when it exists and is not loading', () => {
      const user = UsersMockHelper.createRandomUser();
      createWrapper({
        vulnerability: { state: 'resolved' },
        user,
      });

      expect(userLoadingIcon().exists()).toBe(false);
      expect(userAvatar().props()).toMatchObject({
        linkHref: user.user_path,
        imgSrc: user.avatar_url,
        username: user.name,
      });
    });

    it('does not show the user when it does not exist and is not loading', () => {
      createWrapper();

      expect(userLoadingIcon().exists()).toBe(false);
      expect(userAvatar().exists()).toBe(false);
    });
  });

  describe('skeleton loader', () => {
    it('shows a skeleton loader and does not show anything else when the vulnerability is loading', () => {
      createWrapper({ isLoadingVulnerability: true });

      expect(skeletonLoader().exists()).toBe(true);
      expect(timeAgo().exists()).toBe(false);
      expect(pipelineLink().exists()).toBe(false);
    });

    it('hides the skeleton loader and shows everything else when the vulnerability is not loading', () => {
      createWrapper({ vulnerability: { state: 'detected' } });

      expect(skeletonLoader().exists()).toBe(false);
      expect(timeAgo().exists()).toBe(true);
      expect(pipelineLink().exists()).toBe(true);
    });
  });
});
