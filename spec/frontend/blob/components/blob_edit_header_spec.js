import { shallowMount } from '@vue/test-utils';
import BlobEditHeader from '~/blob/components/blob_edit_header.vue';
import { GlFormInput } from '@gitlab/ui';

describe('Blob Header Editing', () => {
  let wrapper;
  const value = 'foo.md';

  function createComponent() {
    wrapper = shallowMount(BlobEditHeader, {
      propsData: {
        value,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('relies on GlFormInput component', () => {
      expect(wrapper.contains(GlFormInput)).toBe(true);
    });
  });

  describe('functionality', () => {
    it('emits input event when the blob name is changed', () => {
      jest.spyOn(wrapper.vm, '$emit');

      const inputComponent = wrapper.find(GlFormInput);
      const newValue = 'bar.txt';

      wrapper.setData({
        name: newValue,
      });
      inputComponent.vm.$emit('change');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('input', newValue);
      });
    });
  });
});
