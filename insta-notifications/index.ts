import { IgApiClientExt, IgApiClientFbns, withFbns } from 'instagram_mqtt';
import { IgApiClient } from 'instagram-private-api';
import { promisify } from 'util';
import { writeFile, readFile, exists } from 'fs';
import { REST } from '@discordjs/rest';
import { Routes } from 'discord-api-types/v10';
import { EmbedBuilder } from '@discordjs/builders';

var bigInt = require('big-integer');

const writeFileAsync = promisify(writeFile);
const readFileAsync = promisify(readFile);
const existsAsync = promisify(exists);

const IG_USERNAME: any = process.env.USERNAME, IG_PASSWORD: any = process.env.PASSWORD, CHANNEL_ID: any = process.env.CHANNEL_ID, TOKEN: any = process.env.TOKEN, ROLE_ID: any = process.env.ROLE_ID;
const rest = new REST({ version: '10' }).setToken(TOKEN);
const igClient = new IgApiClient();

(async () => {
    const ig: IgApiClientFbns = withFbns(igClient);
    ig.state.generateDevice(IG_USERNAME);

    // this will set the auth and the cookies for instagram
    await readState(ig);

    // this logs the client in
    await loginToInstagram(ig);

    // you received a notification
    ig.fbns.on('push', async push => handle_push(push, ig));

    // the client received auth data
    // the listener has to be added before connecting
    ig.fbns.on('auth', async auth => {
        // logs the auth
        logEvent('auth')(auth);

        //saves the auth
        await saveState(ig);
    });

    // 'error' is emitted whenever the client experiences a fatal error
    ig.fbns.on('error', logEvent('error'));
    // 'warning' is emitted whenever the client errors but the connection isn't affected
    ig.fbns.on('warning', logEvent('warning'));

    // this sends the connect packet to the server and starts the connection
    // the promise will resolve once the client is fully connected (once /push/register/ is received)
    await ig.fbns.connect();

    // you can pass in an object with socks proxy options to use this proxy
    // await ig.fbns.connect({socksOptions: {host: '...', port: 12345, type: 4}});
})();

async function saveState(ig: IgApiClientExt) {
    return writeFileAsync('state.json', await ig.exportState(), { encoding: 'utf8' });
}

async function readState(ig: IgApiClientExt) {
    if (!await existsAsync('state.json'))
        return;
    await ig.importState(await readFileAsync('state.json', {encoding: 'utf8'}));
}

async function loginToInstagram(ig: IgApiClientExt) {
    ig.request.end$.subscribe(() => saveState(ig));
    await ig.account.login(IG_USERNAME, IG_PASSWORD);
}

async function handle_push(data: any, ig: any) {
    switch(data['pushCategory']) {
        case 'subscribed_reel_post':
            await do_reel(data, ig);
            break;
        case 'post':
            await do_post(data);
            break;
        default:
            break;
    }
    console.log(data);
}

async function do_reel(data: any, ig: any) {
    let stories = await ig.feed.userStory(427170733).items();

    await post_alert({
        content: `<@&${ROLE_ID}> New Story!\n${stories[stories.length - 1]["video_versions"][0]["url"]}`,
        components: [{
            type: 1,
            components: [{
                type: 2,
                style: 5,
                url: get_story_url(stories[stories.length - 1]["pk"]),
                label: "View on Instagram"
            }]
        }]
    })
    console.log(stories[stories.length - 1])
}

async function do_post(data: any) {
    let embed = new EmbedBuilder()
        .setImage(data["optionalImage"])
        .setColor(0xE1306C)
        .toJSON()
    
    await post_alert({
        content: `<@&${ROLE_ID}> New Post!`,
        embeds: [embed],
        components: [{
            type: 1,
            components: [{
                type: 2,
                style: 5,
                url: get_post_url(data["actionParams"]["media_id"]),
                label: "View on Instagram"
            }]
        }]
    })
}

async function post_alert(body: any) {
    try {
        let msg: any = await rest.post(Routes.channelMessages(CHANNEL_ID), {
            body: body
        })
        await rest.post(Routes.channelMessageCrosspost(CHANNEL_ID, msg["id"]))
    } catch (error) {
        console.error(error)
    }
}

function get_post_url(media_id: any) {
    return "https://instagram.com/p/" + getShortcodeFromTag(media_id)
}

function get_story_url(media_id: any) {
    return "https://www.instagram.com/stories/radvxz/" + media_id
}

function getShortcodeFromTag(tag: any) {
  let id = bigInt(tag.split('_', 1)[0]);
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
  let shortcode = '';

  while (id.greater(0)) {
    let division = id.divmod(64);
    id = division.quotient;
    shortcode = `${alphabet.charAt(division.remainder)}${shortcode}`;
  }

  return shortcode;
}

function logEvent(name: string) {
    return (data: any) => console.log(name, data);
}