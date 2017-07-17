import PropTypes from 'prop-types'
import React from 'react'
import block from 'bem-cn'
import renderTemplate from 'desktop/components/react/utils/render_template'
import { connect } from 'react-redux'
import { first } from 'underscore'

function Footer (props) {
  const {
    articles,
    footerItem,
    showArticles,
    showFooterItems,
    sd
  } = props

  const b = block('auction2-footer')

  if (!showArticles) {
    return null
  }

  return (
    <footer
      className={b({without: false})
        .mix('auction2-page-section')
        .mix(articles.length ? 'has-articles' : 'has-no-articles')}
    >
      { showArticles &&
        <div className={b('auction2-articles')}>
          { articles.models.map((article, key) => {
            let articleFigureHTML

            // Serverside
            if (typeof window === 'undefined') {
              articleFigureHTML = renderTemplate('desktop/components/article_figure/template.jade', { locals: { article, sd } })

              // Client
            } else {
              articleFigureHTML = require('desktop/components/article_figure/template.jade')({ article, ...sd })
            }

            return (
              <div
                key={key}
                dangerouslySetInnerHTML={{ __html: articleFigureHTML }}
              />
            )
          })}
        </div>
      }

      { showFooterItems &&
        <div className={b('auction2-app-promo-wrapper')}>
          <a className={b('auction2-app-promo')}>
            <div className={b('auction2-app-promo-image')}>
              <img
                src={footerItem.src}
                alt={footerItem.alt}
              />
            </div>
            <div className={b('auction2-app-promo-metadata')}>
              <div className={b('auction2-app-promo-title')}>
                {footerItem.title}
              </div>
              <div className={b('auction2-app-promo-subtitle')}>
                {footerItem.subtitle}
              </div>
            </div>
          </a>
        </div> }
    </footer>
  )
}

Footer.propTypes = {
  articles: PropTypes.object,
  footerItem: PropTypes.object,
  showArticles: PropTypes.bool,
  showFooterItems: PropTypes.bool,
  sd: PropTypes.object.isRequired
}

Footer.defaultProps = {
  articles: {},
  footerItems: []
}

const mapStateToProps = (state) => {
  const { auction, articles, footerItems, sd } = state.app
  const footerItem = first(footerItems)
  const showArticles = Boolean(articles.length)
  const showFooterItems = Boolean(footerItem && !auction.isAuctionPromo())

  return {
    articles,
    footerItem,
    showArticles,
    showFooterItems,
    sd
  }
}

export default connect(
  mapStateToProps
)(Footer)

// Helpers

export const test = { Footer }
