import _request from "superagent"
import { extend } from "underscore"
import { fetchToken as _fetchToken } from "./helpers"
import Analytics from "analytics-node"

const Items = require("../../collections/items")
const JSONPage = require("../../components/json_page")
const markdown = require("../../components/util/markdown")
const _metaphysics = require("lib/metaphysics.coffee")

// FIXME: Rewire
let request = _request
let fetchToken = _fetchToken
let metaphysics = _metaphysics

const landing = new JSONPage({ name: "consignments-landing" })

export const landingPage = async (req, res, next) => {
  const inDemand = new Items([], { item_type: "Artist" })

  try {
    const data = await landing.get()
    const { recently_sold, in_demand } = data.sections
    inDemand.id = in_demand.set.id

    await inDemand.fetch({ cache: true })
    const { ordered_set: recentlySold } = await metaphysics({
      query: RecentlySoldQuery(recently_sold.set.id),
      req,
    })
    const { sales } = await metaphysics({ query: SalesQuery(), req })

    res.locals.sd.RECENTLY_SOLD = recentlySold.artworks
    res.locals.sd.IN_DEMAND = inDemand.toJSON()

    const pageData = extend(data, {
      recentlySold: recentlySold.artworks,
      sales: sales,
      inDemand: inDemand,
      markdown: markdown,
    })
    res.render("landing", pageData)
  } catch (e) {
    next(e)
  }
}

export const submissionFlow = async (req, res, _next) => {
  trackSubmissionStart(req, res)
  res.render("submission_flow", { user: req.user })
}

export const redirectToSubmissionFlow = async (_req, res, _next) => {
  return res.redirect("/consign/submission")
}

export const submissionFlowWithId = async (req, res, _next) => {
  res.locals.sd.SUBMISSION_ID = req.params.id
  res.render("submission_flow", { user: req.user })
}

export const submissionFlowWithFetch = async (req, res, next) => {
  try {
    if (req.user) {
      const token = await fetchToken(req.user.get("accessToken"))
      const submission = await request
        .get(
          `${res.locals.sd.CONVECTION_APP_URL}/api/submissions/${req.params.id}`
        )
        .set("Authorization", `Bearer ${token}`)
      const {
        artist: { name },
      } = await metaphysics({
        query: ArtistQuery(submission.body.artist_id),
        req,
      })
      res.locals.sd.SUBMISSION = submission.body
      res.locals.sd.SUBMISSION_ARTIST_NAME = name
    }
    res.render("submission_flow", { user: req.user })
  } catch (e) {
    next(e)
  }
}

function trackSubmissionStart(req, res) {
  const analytics = new Analytics(res.locals.sd.SEGMENT_WRITE_KEY)
  const userId = req.user?.get("id")
  const anonymousId = res.locals.sd.SESSION_ID

  const event = {
    event: "Clicked consign",
    userId,
    anonymousId,
    properties: {
      context_page_path: req.query.contextPath,
      flow: "consignments",
      subject: "request a price estimate",
    },
  }

  console.log(event)
  analytics.track(event)
}

function ArtistQuery(artistId) {
  return `
  query ConsignArtistQuery {
    artist(id: "${artistId}") {
      id
      name
    }
  }`
}

function RecentlySoldQuery(id) {
  return `
    query ConsignRecentlySoldQuery {
      ordered_set(id: "${id}") {
        id
        name
        artworks: items {
          ... on ArtworkItem {
            id
            title
            date
            artists(shallow: true) {
              name
            }
            partner(shallow: true) {
              name
            }
            image {
              placeholder
              thumb: resized(height: 170, version: ["large", "larger"]) {
                url
                width
              }
            }
          }
        }
      }
    }
  `
}

function SalesQuery() {
  return `
  query ConsignSalesQuery {
    sales(live: true, published: true, is_auction: true, size: 3) {
      _id
      auction_state
      end_at
      id
      is_auction
      is_closed
      is_live_open
      is_open
      live_start_at
      name
      start_at
    }
  }`
}
