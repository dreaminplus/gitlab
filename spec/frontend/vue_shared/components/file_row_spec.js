import { file } from 'jest/ide/helpers';
import FileRow from '~/vue_shared/components/file_row.vue';
import { mount } from '@vue/test-utils';

describe('File row component', () => {
  let wrapper;

  function createComponent(propsData) {
    wrapper = mount(FileRow, {
      propsData,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders name', () => {
    createComponent({
      file: file('t4'),
      level: 0,
    });

    const name = wrapper.find('.file-row-name');

    expect(name.text().trim()).toEqual(wrapper.props('file').name);
  });

  it('emits toggleTreeOpen on click', () => {
    createComponent({
      file: {
        ...file('t3'),
        type: 'tree',
      },
      level: 0,
    });
    jest.spyOn(wrapper.vm, '$emit');

    wrapper.element.click();

    expect(wrapper.vm.$emit).toHaveBeenCalledWith('toggleTreeOpen', wrapper.props('file').path);
  });

  it('calls scrollIntoView if made active', () => {
    createComponent({
      file: {
        ...file(),
        type: 'blob',
        active: false,
      },
      level: 0,
    });

    jest.spyOn(wrapper.vm, 'scrollIntoView');

    wrapper.setProps({
      file: Object.assign({}, wrapper.props('file'), {
        active: true,
      }),
    });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.vm.scrollIntoView).toHaveBeenCalled();
    });
  });

  it('indents row based on level', () => {
    createComponent({
      file: file('t4'),
      level: 2,
    });

    expect(wrapper.find('.file-row-name').element.style.marginLeft).toBe('32px');
  });

  it('renders header for file', () => {
    createComponent({
      file: {
        isHeader: true,
        path: 'app/assets',
        tree: [],
      },
      level: 0,
    });

    expect(wrapper.element.classList).toContain('js-file-row-header');
  });
});
