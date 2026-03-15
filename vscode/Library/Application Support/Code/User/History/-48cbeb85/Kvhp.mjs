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
        callout: {
            render: component('./src/components/Callout.astro'),
            attributes: {
                type: {
                    type: String,
                    default: 'info',
                    matches: ['info', 'tip', 'warning', 'danger'],
                    description: 'The style/color of the callout box',
                },
                title: {
                    type: String,
                    required: false,
                    description: 'Optional title for the callout',
                },
            },
        },
    },
});
