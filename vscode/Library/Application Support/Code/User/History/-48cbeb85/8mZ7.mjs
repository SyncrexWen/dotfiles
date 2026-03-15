// markdoc.config.mjs
import { defineMarkdocConfig, component } from '@astrojs/markdoc/config';

export default defineMarkdocConfig({
    tags: {
        box: {
            render: component('./src/components/IllustrateBox.astro'),
            attributes: {
                title: {
                    type: [String, Object],
                    required: true,
                    description: 'title of the box',
                },
                default_show: {
                    type: Boolean,
                    required: false,
                    description: 'whether the box is open by default',
                },
            },
        },
    },
});
