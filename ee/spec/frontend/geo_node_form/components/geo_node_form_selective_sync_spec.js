import { mount } from '@vue/test-utils';
import GeoNodeFormSelectiveSync from 'ee/geo_node_form/components/geo_node_form_selective_sync.vue';
import GeoNodeFormNamespaces from 'ee/geo_node_form/components/geo_node_form_namespaces.vue';
import GeoNodeFormShards from 'ee/geo_node_form/components/geo_node_form_shards.vue';
import { MOCK_NODE, MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoNodeFormSelectiveSync', () => {
  let wrapper;

  const propsData = {
    nodeData: MOCK_NODE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = () => {
    wrapper = mount(GeoNodeFormSelectiveSync, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormSyncContainer = () =>
    wrapper.find({ ref: 'geoNodeFormSelectiveSyncContainer' });
  const findGeoNodeFormSyncTypeField = () => wrapper.find('#node-selective-synchronization-field');
  const findGeoNodeFormNamespacesField = () => wrapper.find(GeoNodeFormNamespaces);
  const findGeoNodeFormShardsField = () => wrapper.find(GeoNodeFormShards);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Node Form Sync Container', () => {
      expect(findGeoNodeFormSyncContainer().exists()).toBe(true);
    });

    it('renders Geo Node Sync Type Field', () => {
      expect(findGeoNodeFormSyncTypeField().exists()).toBe(true);
    });

    describe.each`
      syncType                                | showNamespaces | showShards
      ${MOCK_SELECTIVE_SYNC_TYPES.ALL}        | ${false}       | ${false}
      ${MOCK_SELECTIVE_SYNC_TYPES.NAMESPACES} | ${true}        | ${false}
      ${MOCK_SELECTIVE_SYNC_TYPES.SHARDS}     | ${false}       | ${true}
    `(`sync type`, ({ syncType, showNamespaces, showShards }) => {
      beforeEach(() => {
        createComponent();
        wrapper.setProps({
          nodeData: { ...propsData.nodeData, selectiveSyncType: syncType.value },
        });
      });

      it(`${showNamespaces ? 'show' : 'hide'} Namespaces Field`, () => {
        expect(findGeoNodeFormNamespacesField().exists()).toBe(showNamespaces);
      });

      it(`${showShards ? 'show' : 'hide'} Shards Field`, () => {
        expect(findGeoNodeFormShardsField().exists()).toBe(showShards);
      });
    });
  });

  describe('methods', () => {
    describe('addSyncOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('emits `addSyncOption`', () => {
        wrapper.vm.addSyncOption({ key: 'selectiveSyncShards', value: MOCK_SYNC_SHARDS[0].value });
        expect(wrapper.emitted('addSyncOption')).toBeTruthy();
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent();
        wrapper.setProps({
          nodeData: { ...propsData.nodeData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from nodeData', () => {
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.emitted('removeSyncOption')).toBeTruthy();
      });
    });
  });

  describe('computed', () => {
    describe('selectiveSyncNamespaces', () => {
      describe('when selectiveSyncType is not `NAMESPACES`', () => {
        beforeEach(() => {
          createComponent();
          wrapper.setProps({
            nodeData: {
              ...propsData.nodeData,
              selectiveSyncType: MOCK_SELECTIVE_SYNC_TYPES.ALL.value,
            },
          });
        });

        it('returns `false`', () => {
          expect(wrapper.vm.selectiveSyncNamespaces).toBeFalsy();
        });
      });

      describe('when selectiveSyncType is `NAMESPACES`', () => {
        beforeEach(() => {
          createComponent();
          wrapper.setProps({
            nodeData: {
              ...propsData.nodeData,
              selectiveSyncType: MOCK_SELECTIVE_SYNC_TYPES.NAMESPACES.value,
            },
          });
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncNamespaces).toBeTruthy();
        });
      });
    });

    describe('selectiveSyncShards', () => {
      describe('when selectiveSyncType is not `SHARDS`', () => {
        beforeEach(() => {
          createComponent();
          wrapper.setProps({
            nodeData: {
              ...propsData.nodeData,
              selectiveSyncType: MOCK_SELECTIVE_SYNC_TYPES.ALL.value,
            },
          });
        });

        it('returns `false`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBeFalsy();
        });
      });

      describe('when selectiveSyncType is `SHARDS`', () => {
        beforeEach(() => {
          createComponent();
          wrapper.setProps({
            nodeData: {
              ...propsData.nodeData,
              selectiveSyncType: MOCK_SELECTIVE_SYNC_TYPES.SHARDS.value,
            },
          });
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBeTruthy();
        });
      });
    });
  });
});
